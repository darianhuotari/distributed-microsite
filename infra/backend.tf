terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }

  backend "azurerm" {
    key = "micro-site.tfstate"
  }

  required_version = ">= 1.12"
}
