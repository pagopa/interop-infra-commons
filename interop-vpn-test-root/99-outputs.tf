
output "vpc_id" {
  description = "ID del VPC usato dal root"
  value       = local.resolved_vpc_id
}

output "subnet_id" {
  description = "ID della subnet di test creata dal root, se presente"
  value       = var.create_test_network ? aws_subnet.main[0].id : null
}

output "mutual_cert_endpoint_id" {
  description = "Client VPN endpoint ID (mutual-cert)"
  value       = var.enable_mutual_cert_vpn ? module.vpn_mutual_cert[0].endpoint_id : null
}

output "mutual_cert_endpoint_dns" {
  description = "DNS del VPN endpoint mutual-cert (da usare nel .ovpn)"
  value       = var.enable_mutual_cert_vpn ? module.vpn_mutual_cert[0].endpoint_dns : null
}

output "mutual_cert_subnet_ids" {
  description = "Subnet IDs configurate per l'associazione all'endpoint mutual-cert"
  value       = var.mutual_cert_subnet_ids
}

output "saml_subnet_ids" {
  description = "Subnet IDs configurate per l'associazione all'endpoint SAML"
  value       = var.saml_subnet_ids
}

output "server_certificate_arn" {
  description = "ARN ACM del certificato server (mutual-cert)"
  value       = var.enable_mutual_cert_vpn ? module.vpn_mutual_cert[0].server_certificate_arn : null
}

output "client_ca_arn" {
  description = "ARN ACM del client CA (mutual-cert)"
  value       = var.enable_mutual_cert_vpn ? module.vpn_mutual_cert[0].client_ca_arn : null
}

output "admin_key_secret_arn" {
  description = "ARN Secrets Manager della chiave privata admin (write-only, non in state)"
  value       = var.enable_mutual_cert_vpn ? module.vpn_mutual_cert[0].admin_key_secret_arn : null
}

output "saml_endpoint_id" {
  description = "Client VPN endpoint ID (SAML). Null se SAML non è abilitato."
  value       = local.is_saml ? module.vpn_saml[0].endpoint_id : null
}

output "saml_endpoint_dns" {
  description = "DNS del VPN endpoint SAML. Null se SAML non è abilitato."
  value       = local.is_saml ? module.vpn_saml[0].endpoint_dns : null
}

output "saml_provider_arn" {
  description = "ARN del SAML provider IAM. Null se SAML non è abilitato."
  value       = local.is_saml ? module.vpn_saml[0].saml_provider_arn : null
}
