output "vm_id" {
  description = "ID of the virtual machine"
  value       = var.os_type == "linux" ? azurerm_linux_virtual_machine.main[0].id : azurerm_windows_virtual_machine.main[0].id
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = var.os_type == "linux" ? azurerm_linux_virtual_machine.main[0].name : azurerm_windows_virtual_machine.main[0].name
}

output "private_ip_address" {
  description = "Private IP address of the VM"
  value       = azurerm_network_interface.main.private_ip_address
}

output "public_ip_address" {
  description = "Public IP address of the VM (if created)"
  value       = var.create_public_ip ? azurerm_public_ip.main[0].ip_address : null
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

output "network_interface_id" {
  description = "ID of the network interface"
  value       = azurerm_network_interface.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = azurerm_subnet.main.id
}

output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "ssh_connection_command" {
  description = "SSH connection command (for Linux VMs with public IP)"
  value       = var.os_type == "linux" && var.create_public_ip ? "ssh ${var.admin_username}@${azurerm_public_ip.main[0].ip_address}" : null
}