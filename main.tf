terraform {
  required_providers {
    volterra = {
      source = "volterraedge/volterra"
      # version = "0.11.9"
      version = "0.11.43"
    }
    http-full = {
      source = "salrashid123/http-full"
    }
    jq = {
      source  = "massdriver-cloud/jq"
      version = "0.2.0"
    }
  }

  backend "azurerm" {
    resource_group_name  = "arch-storage-rg"
    storage_account_name = "xcterraformgithubactions"
    container_name       = "terraform"
    key                  = "terraform.tfstat"
  }
}

provider "volterra" {
  url          = local.api_url
  api_p12_file = var.api_p12_file

}

provider "http-full" {}

provider "jq" {}