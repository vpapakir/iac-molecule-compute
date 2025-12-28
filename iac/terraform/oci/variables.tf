variable "name_prefix" {
  description = "Prefix for all resource names"
  type        = string
}

variable "compartment_id" {
  description = "OCI compartment ID"
  type        = string
  default     = "ocid1.compartment.oc1..example" # Mock compartment for validation
}

variable "instance_shape" {
  description = "Instance shape"
  type        = string
  default     = "VM.Standard.E4.Flex"
}

variable "instance_shape_config" {
  description = "Instance shape configuration for flexible shapes"
  type = object({
    ocpus         = number
    memory_in_gbs = number
  })
  default = {
    ocpus         = 1
    memory_in_gbs = 6
  }
}

variable "image_id" {
  description = "Custom image ID (if not specified, will use latest based on filters)"
  type        = string
  default     = null
}

variable "image_operating_system" {
  description = "Operating system for image lookup"
  type        = string
  default     = "Canonical Ubuntu"
}

variable "image_operating_system_version" {
  description = "Operating system version for image lookup"
  type        = string
  default     = "22.04"
}

variable "image_name_filter" {
  description = "Image name filter for lookup"
  type        = string
  default     = ".*aarch64.*"
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = null
}

variable "vcn_cidr" {
  description = "CIDR block for VCN"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "CIDR block for subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "create_public_ip" {
  description = "Whether to create public IP and internet gateway"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = null
}

variable "ingress_rules" {
  description = "List of ingress security rules"
  type = list(object({
    protocol = string
    source   = string
    port_min = number
    port_max = number
  }))
  default = [
    {
      protocol = "6" # TCP
      source   = "0.0.0.0/0"
      port_min = 22
      port_max = 22
    }
  ]
}

variable "tags" {
  description = "Freeform tags to apply to all resources"
  type        = map(string)
  default     = {}
}