data "aws_secretsmanager_random_password" "this" {
  password_length     = var.generated_password_length
  exclude_punctuation = !var.generated_password_use_special_characters
}

resource "aws_secretsmanager_secret" "this" {
  name                    = "${var.secret_prefix}${var.username}"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.secret_tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id

  secret_string_wo = jsonencode({
    database = var.db_name
    username = var.username
    password = data.aws_secretsmanager_random_password.this.random_password
  })

  secret_string_wo_version = var.secret_string_wo_version
}
