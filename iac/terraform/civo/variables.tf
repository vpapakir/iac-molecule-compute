variable "name_prefix" {
  description = "Prefix for all resource name"
  type        = string
}

variable "region" {
  description = "Civo region"
  type        = string
  default     = "LON1"
}

variable "instance_size" {
  description = "Instance size"
  type        = string
  default     = "g3.small"
}

variable "disk_image" {
  description = "Disk image UUID"
  type        = string
  default     = "a4204155-a876-43fa-b4d6-ea2af8774560"  # ubuntu-22.04-server
}

variable "ssh_public_key" {
  description = "SSH public key"
  type        = string
  default     = null
}

variable "create_public_ip" {
  description = "Whether to create a public IP"
  type        = bool
  default     = true
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = null
}

variable "firewall_rules" {
  description = "List of firewall ingress rules"
  type = list(object({
    protocol   = string
    port_range = string
    cidr       = list(string)
    label      = string
  }))
  default = [
    {
      protocol   = "tcp"
      port_range = "22"
      cidr       = ["0.0.0.0/0"]
      label      = "SSH"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []
}