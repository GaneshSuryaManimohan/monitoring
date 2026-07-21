output "instance_ids" {
  description = "Map of instance name to instance ID"
  value       = { for name, inst in aws_instance.monitoring : name => inst.id }
}

output "instance_private_ips" {
  description = "Map of instance name to private IP address"
  value       = { for name, inst in aws_instance.monitoring : name => inst.private_ip }
}

output "instance_public_ips" {
  description = "Map of instance name to public IP address (if assigned)"
  value       = { for name, inst in aws_instance.monitoring : name => inst.public_ip }
}