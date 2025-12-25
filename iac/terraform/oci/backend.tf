terraform {
  cloud {
    organization = "vpapakir"
    
    workspaces {
      name = "compute-oci-dev"
    }
  }
  
  required_version = ">= 1.0"
  
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}