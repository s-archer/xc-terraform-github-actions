terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.9"
    }
    # azurerm = {
    #   source  = "hashicorp/azurerm"
    #   version = "=2.46.0"
    # }
  }
  cloud {
    organization = "f5ukse"

    workspaces {
      name = "xc-terraform-github-actions"
    }
  }
}

provider "volterra" {
  # Configuration options.
  url          = format("https://%s.console.ves.volterra.io/api", var.TENANT)
  api_p12_file = base64decode(var.VOLT_API_P12_FILE)
}



resource "volterra_origin_pool" "gcp-origin" {
  name                   = format("gcp-%s-tf", var.SHORTNAME)
  namespace              = var.NAMESPACE
  description            = "Created by Terraform"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  port   = var.ORIGIN_PORT
  no_tls = true

  origin_servers {
    private_ip {
      ip              = var.ORIGIN_IP
      outside_network = true
      site_locator {
        site {
          tenant    = null
          namespace = "system"
          name      = var.ORIGIN_SITE
        }
      }
    }
  }
}

resource "volterra_http_loadbalancer" "gcp-nginx-lb" {
  name        = format("gcp-%s-tf", var.SHORTNAME)
  namespace   = var.NAMESPACE
  description = "Created by Terraform"
  domains     = [var.DOMAIN_NAME]

  advertise_on_public_default_vip = true
  no_challenge                    = true
  round_robin                     = true
  disable_rate_limit              = true
  no_service_policies             = true
  disable_waf                     = true
  multi_lb_app                    = true
  user_id_client_ip               = true

  https_auto_cert {
    add_hsts               = false
    http_redirect          = true
    no_mtls                = true
    default_header         = true
    disable_path_normalize = true

    tls_config {
      default_security = true
    }
  }

  default_route_pools {
    pool {
      name      = volterra_origin_pool.gcp-origin.name
      namespace = var.NAMESPACE
    }
    weight = 1
  }
}