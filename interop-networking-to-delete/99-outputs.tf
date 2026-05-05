output "vpc_id" {
  description = "ID del VPC usato dal root"
  value       = local.resolved_vpc_id
}

output "subnet_id" {
  description = "ID della subnet di test creata dal root, se presente"
  value       = var.create_networking_resources ? aws_subnet.main[0].id : null
}

output "subnet_ids" {
  description = "Subnet IDs configurate per l'associazione all'endpoint"
  value       = local.endpoint_subnet_ids
}
