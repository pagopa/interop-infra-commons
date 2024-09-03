output "ses_identity_arn" {
  description = "ARN of the SES Identity managed by this module"
  value       = aws_sesv2_email_identity.this.arn
}

output "ses_identity_name" {
  description = "Name of the SES Identity managed by this module"
  value       = aws_sesv2_email_identity.this.email_identity
}

output "ses_configuration_set_arn" {
  description = "ARN of the Configuration Set managed by this module"
  value       = aws_sesv2_configuration_set.this.arn
}

output "ses_configuration_set_name" {
  description = "Name of the Configuration Set managed by this module"
  value       = aws_sesv2_configuration_set.this.configuration_set_name
}