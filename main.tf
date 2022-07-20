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

resource "volterra_origin_pool" "origin" {
  name                   = format("%s-%s-tf", var.uk_se_name, var.short_name)
  namespace              = var.namespace
  description            = "Terraform created origin pool"
  loadbalancer_algorithm = "LB_OVERRIDE"

  origin_servers {
    public_name {
      dns_name = var.origin_fqdn
    }
  }
  port               = var.origin_port
  endpoint_selection = "LOCAL_PREFERRED"
  use_tls {
    no_mtls                  = true
    skip_server_verification = true
    tls_config {
      default_security = true
    }
    use_host_header_as_sni = true
  }
}

resource "volterra_http_loadbalancer" "lb" {
  name        = format("%s-%s-tf", var.uk_se_name, var.short_name)
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
      name      = volterra_origin_pool.origin.name
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
  name      = format("%s-%s-tf", var.uk_se_name, var.short_name)
  namespace = var.namespace

  allow_all_response_codes   = true
  default_anonymization      = true
  use_default_blocking_page  = true
  default_bot_setting        = true
  default_detection_settings = true
  use_loadbalancer_setting   = true
}