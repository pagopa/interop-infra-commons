output "secret_arn" {
  description = "User credentials secret ARN"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  description = "User credentials secret ID"
  value       = aws_secretsmanager_secret.this.id
}
