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
  url          = format("https://%s.console.ves.volterra.io/api", var.tenant)
  api_p12_file = var.api_p12_file
}



resource "volterra_origin_pool" "gcp-origin" {
  name                   = format("gcp-%s-tf", var.shortname)
  namespace              = var.namespace
  description            = "Created by Terraform"
  endpoint_selection     = "LOCAL_PREFERRED"
  loadbalancer_algorithm = "LB_OVERRIDE"

  port   = var.origin_port
  no_tls = true

  origin_servers {
    private_ip {
      ip              = var.origin_ip
      outside_network = true
      site_locator {
        site {
          tenant    = null
          namespace = "system"
          name      = var.origin_site
        }
      }
    }
  }
}

resource "volterra_http_loadbalancer" "gcp-nginx-lb" {
  name        = format("gcp-%s-tf", var.shortname)
  namespace   = var.namespace
  description = "Created by Terraform"
  domains     = [var.domain_name]

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
      namespace = var.namespace
    }
    weight = 1
  }

  app_firewall {
    name      = volterra_app_firewall.recommended.name
    namespace = var.namespace
  }
}

resource "volterra_app_firewall" "recommended" {
  name      = format("gcp-%s-waf-tf", var.shortname)
  namespace = var.namespace

  allow_all_response_codes   = true
  default_anonymization      = true
  use_default_blocking_page  = true
  default_bot_setting        = true
  default_detection_settings = true
  use_loadbalancer_setting   = true
}