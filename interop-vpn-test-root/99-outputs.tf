output "vpc_id" {
  description = "ID del VPC usato dal root"
  value       = local.resolved_vpc_id
}

output "subnet_id" {
  description = "ID della subnet di test creata dal root, se presente"
  value       = var.create_networking_resources ? aws_subnet.main[0].id : null
}

output "mutual_cert_endpoint_id" {
  description = "Client VPN endpoint ID (mutual-cert). Null if create_mutual_cert_vpn is false."
  value       = one(module.vpn_mutual_cert[*].endpoint_id)
}

output "mutual_cert_endpoint_dns" {
  description = "DNS del VPN endpoint (mutual-cert). Null if create_mutual_cert_vpn is false."
  value       = one(module.vpn_mutual_cert[*].endpoint_dns)
}

output "saml_endpoint_id" {
  description = "Client VPN endpoint ID (saml). Null if create_saml_vpn is false."
  value       = one(module.vpn_saml[*].endpoint_id)
}

output "saml_endpoint_dns" {
  description = "DNS del VPN endpoint (saml). Null if create_saml_vpn is false."
  value       = one(module.vpn_saml[*].endpoint_dns)
}

output "subnet_ids" {
  description = "Subnet IDs configurate per l'associazione all'endpoint"
  value       = local.endpoint_subnet_ids
}

output "server_certificate_arn" {
  description = "ARN ACM del certificato server"
  value       = coalesce(one(module.vpn_mutual_cert[*].server_certificate_arn), one(module.vpn_saml[*].server_certificate_arn))
}

output "client_ca_arn" {
  description = "ARN ACM del client CA. Null if create_mutual_cert_vpn is false."
  value       = one(module.vpn_mutual_cert[*].client_ca_arn)
}

output "saml_provider_arn" {
  description = "ARN del SAML provider IAM. Null if create_saml_vpn is false."
  value       = one(module.vpn_saml[*].saml_provider_arn)
}
