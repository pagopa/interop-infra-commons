
# Random password generation
# the "random" provider provides an idea of managed randomness: 
# it provides resources that generate random values during their creation 
# and then hold those values steady until the inputs are changed.
resource "random_password" "password" {
  length           = 30
  special          = true
  override_special = "\\'\\`\"@/\\"
}

resource "aws_secretsmanager_secret" "secret" {
  name = "${var.secret_prefix}${var.username}"
  tags = var.secret_tags
}

resource "aws_secretsmanager_secret_version" "secret_version" {
  secret_id = aws_secretsmanager_secret.secret.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.password.result
    database = var.db_name
  })
}