terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

module "compute" {
  source = "../../iac/terraform/azure"
  
  name_prefix         = "example-dev"
  resource_group_name = "rg-example-dev"  # Replace with your resource group
  location           = "East US"
  vm_size            = "Standard_B2s"
  os_type            = "linux"
  admin_username     = "azureuser"
  ssh_public_key     = "ssh-rsa AAAAB3NzaC1yc2EAAAA..."  # Replace with your SSH key
  create_public_ip   = true
  os_disk_type       = "Standard_LRS"
  
  tags = {
    Environment = "dev"
    Project     = "compute-molecule-test"
    Owner       = "pipeline"
  }
}

output "vm_id" {
  value = module.compute.vm_id
}

output "public_ip" {
  value = module.compute.public_ip_address
}

output "ssh_command" {
  value = module.compute.ssh_connection_command
}