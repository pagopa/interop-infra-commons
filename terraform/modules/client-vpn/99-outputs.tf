output "endpoint_id" {
  description = "Client VPN endpoint ID."
  value       = aws_ec2_client_vpn_endpoint.this.id
}

output "endpoint_dns" {
  description = "DNS name of the Client VPN endpoint."
  value       = aws_ec2_client_vpn_endpoint.this.dns_name
}

output "server_certificate_arn" {
  description = "ACM ARN of the server certificate."
  value       = local.server_cert_arn
}

output "client_ca_arn" {
  description = "ACM ARN of the client CA certificate. Null when use_saml_auth is true."
  value       = local.client_ca_cert_arn
}

output "saml_provider_arn" {
  description = "IAM SAML provider ARN. Null when use_mutual_auth is true."
  value       = local.saml_provider_arn
}

output "security_group_id" {
  description = "Security group ID attached to the VPN endpoint. Null if create_security_group is false."
  value       = var.create_security_group ? one(aws_security_group.vpn[*].id) : null
}
