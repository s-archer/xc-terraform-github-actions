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
    http-full = {
      source = "salrashid123/http-full"
    }
    jq = {
      source  = "massdriver-cloud/jq"
      version = "0.2.0"
    }
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

provider "http-full" {}

provider "jq" {}