output "domain_certificate_arn" {
  description = "ARN of the domain certificate issued by Amazon"
  value       = aws_acm_certificate.this.arn
}

output "apigw_custom_domain_name" {
  description = "Custom domain name to be used by APIGW"
  value       = aws_api_gateway_domain_name.this.domain_name
}
