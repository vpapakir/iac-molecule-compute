terraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}

provider "oci" {
  tenancy_ocid     = var.tenancy_ocid
  user_ocid        = var.user_ocid
  fingerprint      = var.fingerprint
  private_key      = var.private_key
  region           = var.region
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-ashburn-1"
}

variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
  default     = ""
}

variable "user_ocid" {
  description = "OCI user OCID"
  type        = string
  default     = ""
}

variable "fingerprint" {
  description = "OCI API key fingerprint"
  type        = string
  default     = ""
}

variable "private_key" {
  description = "OCI private key content"
  type        = string
  default     = ""
  sensitive   = true
}

variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = null
}

module "oci_compute" {
  source = "../../iac/terraform/oci"

  name_prefix    = "test-oci"
  compartment_id = var.compartment_id != null ? var.compartment_id : "ocid1.compartment.oc1..example"
  
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