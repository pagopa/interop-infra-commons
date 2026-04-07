output "secret_arn" {
  description = "User credentials secret ARN"
  value       = aws_secretsmanager_secret.this.arn
}

output "secret_id" {
  description = "User credentials secret ID"
  value       = aws_secretsmanager_secret.this.id
}

output "secret_name" {
  description = "User credentials secret name"
  value       = aws_secretsmanager_secret.this.name
}
