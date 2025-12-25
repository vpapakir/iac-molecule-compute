terraform {
  cloud {
    organization = "vpapakir"
    
    workspaces {
      name = "compute-azure-dev"
    }
  }
  
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}