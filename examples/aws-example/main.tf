terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "compute" {
  source = "../../iac/terraform/aws"
  
  name_prefix     = "example-dev"
  instance_type   = "t3.micro"
  ssh_public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAA..."  # Replace with your SSH key
  create_public_ip = true
  root_volume_type = "gp3"
  root_volume_size = 20
  
  tags = {
    Environment = "dev"
    Project     = "compute-molecule-test"
    Owner       = "pipeline"
  }
}

output "instance_id" {
  value = module.compute.instance_id
}

output "public_ip" {
  value = module.compute.public_ip
}

output "ssh_command" {
  value = module.compute.ssh_connection_command
}