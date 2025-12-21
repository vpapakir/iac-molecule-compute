output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_arn" {
  description = "ARN of the EC2 instance"
  value       = aws_instance.main.arn
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "public_ip" {
  description = "Public IP address of the instance (if created)"
  value       = aws_instance.main.public_ip
}

output "public_dns" {
  description = "Public DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = aws_subnet.main.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.main.id
}

output "key_pair_name" {
  description = "Name of the key pair (if created)"
  value       = var.ssh_public_key != null ? aws_key_pair.main[0].key_name : null
}

output "ssh_connection_command" {
  description = "SSH connection command (if public IP and key pair exist)"
  value       = var.create_public_ip && var.ssh_public_key != null ? "ssh -i ~/.ssh/your-private-key ubuntu@${aws_instance.main.public_ip}" : null
}