terraform {
  cloud {
    organization = "vpapakir"
    
    workspaces {
      name = "compute-aws-dev"
    }
  }
  
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}