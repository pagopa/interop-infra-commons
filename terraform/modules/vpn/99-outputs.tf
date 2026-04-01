
output "endpoint_id" {
  description = "Client VPN endpoint ID"
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "endpoint_dns" {
  description = "DNS name of the Client VPN endpoint"
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "server_certificate_arn" {
  description = "ACM ARN of the server certificate (created internally or external)"
  value       = local.server_cert_arn
}

output "client_ca_arn" {
  description = "ACM ARN of the client CA certificate (mutual-cert mode only, created internally or external)"
  value       = local.client_ca_cert_arn
}

output "saml_provider_arn" {
  description = "IAM SAML provider ARN (saml mode only)"
  value       = local.saml_provider_arn
}

output "admin_key_secret_arn" {
  description = "Secrets Manager ARN of the admin private key (mutual-cert, write-only). Null if create_secrets = false."
  value       = local.create_client_pki && var.create_secrets ? one(aws_secretsmanager_secret.admin_key[*].arn) : null
}

output "security_group_id" {
  description = "Security group ID attached to the VPN endpoint (null if create_security_group = false)"
  value       = var.create_security_group ? one(aws_security_group.vpn[*].id) : null
}
