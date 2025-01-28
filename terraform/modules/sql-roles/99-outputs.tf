output "secret_arn" {
  description = "Secret ARN saved in AWS Secrets Manager."
  value       = aws_secretsmanager_secret.secret.arn
}

output "secret_id" {
  description = "Secret ID saved in AWS Secrets Manager."
  value       = aws_secretsmanager_secret.secret.id
}
