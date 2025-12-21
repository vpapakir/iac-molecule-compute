output "instance_id" {
  description = "ID of the Civo instance"
  value       = civo_instance.main.id
}

output "instance_hostname" {
  description = "Hostname of the instance"
  value       = civo_instance.main.hostname
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = civo_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance"
  value       = civo_instance.main.public_ip
}

output "network_id" {
  description = "ID of the network"
  value       = civo_network.main.id
}

output "firewall_id" {
  description = "ID of the firewall"
  value       = civo_firewall.main.id
}

output "ssh_key_id" {
  description = "ID of the SSH key (if created)"
  value       = var.ssh_public_key != null ? civo_ssh_key.main[0].id : null
}

output "ssh_connection_command" {
  description = "SSH connection command"
  value       = var.create_public_ip && var.ssh_public_key != null ? "ssh -i ~/.ssh/your-private-key root@${civo_instance.main.public_ip}" : null
}