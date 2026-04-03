output "vpc_id" {
  description = "ID del VPC usato dal root"
  value       = local.resolved_vpc_id
}

output "subnet_id" {
  description = "ID della subnet di test creata dal root, se presente"
  value       = var.create_test_network ? aws_subnet.main[0].id : null
}

output "endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = module.vpn.endpoint_id
}

output "endpoint_dns" {
  description = "DNS del VPN endpoint"
  value       = module.vpn.endpoint_dns
}

output "subnet_ids" {
  description = "Subnet IDs configurate per l'associazione all'endpoint"
  value       = local.endpoint_subnet_ids
}

output "server_certificate_arn" {
  description = "ARN ACM del certificato server"
  value       = module.vpn.server_certificate_arn
}

output "client_ca_arn" {
  description = "ARN ACM del client CA. Null se vpn_type = saml."
  value       = module.vpn.client_ca_arn
}

output "saml_provider_arn" {
  description = "ARN del SAML provider IAM. Null se vpn_type = mutual-cert."
  value       = module.vpn.saml_provider_arn
}
