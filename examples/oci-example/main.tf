terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  # Authentication will be provided via OCI CLI config or environment variables
  region = var.region
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
  # This should be provided via terraform.tfvars or environment variable
}

module "oci_compute" {
  source = "../../iac/terraform/oci"

  name_prefix    = "test-oci"
  compartment_id = var.compartment_id
  
  instance_shape = "VM.Standard.E4.Flex"
  instance_shape_config = {
    ocpus         = 1
    memory_in_gbs = 6
  }
  
  image_operating_system         = "Canonical Ubuntu"
  image_operating_system_version = "22.04"
  image_name_filter             = ".*aarch64.*"
  
  vcn_cidr    = "10.0.0.0/16"
  subnet_cidr = "10.0.1.0/24"
  
  create_public_ip = true
  
  ingress_rules = [
    {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      port_min = 22
      port_max = 22
    },
    {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      port_min = 80
      port_max = 80
    }
  ]
  
  tags = {
    Environment = "test"
    Project     = "iac-molecule-compute"
    ManagedBy   = "terraform"
  }
}

output "instance_details" {
  value = {
    instance_id       = module.oci_compute.instance_id
    instance_name     = module.oci_compute.instance_display_name
    private_ip        = module.oci_compute.private_ip
    public_ip         = module.oci_compute.public_ip
    availability_domain = module.oci_compute.availability_domain
    ssh_command       = module.oci_compute.ssh_connection_command
  }
}