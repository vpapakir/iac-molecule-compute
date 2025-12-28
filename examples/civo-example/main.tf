terraform {
  required_providers {
    civo = {
      source  = "civo/civo"
      version = "~> 1.0"
    }
  }
}

provider "civo" {
  # Token will be provided via CIVO_TOKEN environment variable
}

module "civo_compute" {
  source = "../../iac/terraform/civo"

  name_prefix       = "test-civo"
  region           = "LON1"
  instance_size    = "g3.small"
  disk_image       = "ubuntu-22.04-server"
  create_public_ip = true
  
  firewall_rules = [
    {
      protocol   = "tcp"
      port_range = "22"
      cidr       = ["0.0.0.0/0"]
      label      = "SSH"
    },
    {
      protocol   = "tcp"
      port_range = "80"
      cidr       = ["0.0.0.0/0"]
      label      = "HTTP"
    }
  ]
  
  tags = ["test", "civo", "compute"]
}

output "instance_details" {
  value = {
    instance_id = module.civo_compute.instance_id
    hostname    = module.civo_compute.instance_hostname
    private_ip  = module.civo_compute.private_ip
    public_ip   = module.civo_compute.public_ip
    ssh_command = module.civo_compute.ssh_connection_command
  }
}