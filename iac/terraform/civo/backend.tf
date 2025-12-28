terraform {
  cloud {
    organization = "vpapakir"

    workspaces {
      name = "compute-civo-dev"
    }
  }

  required_version = ">= 1.0"

  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.0"
    }
  }
}