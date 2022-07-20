terraform {
  required_providers {
    volterra = {
      source  = "volterraedge/volterra"
      version = "0.11.9"
    }
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
  url          = local.api_url
  api_p12_file = var.api_p12_file
}

provider "http-full" {}

provider "jq" {}