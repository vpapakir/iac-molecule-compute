output "instance_id" {
  description = "OCID of the instance"
  value       = oci_core_instance.main.id
}

output "instance_display_name" {
  description = "Display name of the instance"
  value       = oci_core_instance.main.display_name
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = oci_core_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = oci_core_instance.main.public_ip
}

output "vcn_id" {
  description = "OCID of the VCN"
  value       = oci_core_vcn.main.id
}

output "subnet_id" {
  description = "OCID of the subnet"
  value       = oci_core_subnet.main.id
}

output "security_list_id" {
  description = "OCID of the security list"
  value       = oci_core_security_list.main.id
}

output "availability_domain" {
  description = "Availability domain of the instance"
  value       = oci_core_instance.main.availability_domain
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = var.create_public_ip && var.ssh_public_key != null ? "ssh -i ~/.ssh/your-private-key ubuntu@${oci_core_instance.main.public_ip}" : null
}