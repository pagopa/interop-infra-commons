resource "aws_secretsmanager_secret" "admin_key" {
  count                   = local.generate_client_admin_cert && var.create_secrets ? 1 : 0
  name                    = "${local.secret_prefix}/admin-client-key"
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-admin-key" })
}
# Repro SM : commentato, decommentare per creare la chiave su tf
# resource "aws_secretsmanager_secret_version" "admin_key" {
#   count                    = local.generate_client_admin_cert && var.create_secrets ? 1 : 0
#   secret_id                = aws_secretsmanager_secret.admin_key[0].id
#   # Repro ephemeral:
#   # secret_string_wo = ephemeral.tls_private_key.client_admin.private_key_pem
#   secret_string_wo         = tls_private_key.client_admin[0].private_key_pem
#   secret_string_wo_version = var.admin_key_version
# }

# Repro SM:
data "aws_secretsmanager_secret_version" "admin_key_external" {
  count     = var.external_client_admin_key_secret_arn != null ? 1 : 0
  secret_id = var.external_client_admin_key_secret_arn
}

# Repro SM:
data "aws_secretsmanager_secret_version" "server_key_external" {
  count     = var.external_server_key_secret_arn != null ? 1 : 0
  secret_id = var.external_server_key_secret_arn
}

resource "aws_secretsmanager_secret" "admin_cert" {
  count                   = local.generate_client_admin_cert && var.create_secrets ? 1 : 0
  name                    = "${local.secret_prefix}/admin-client-cert"
  recovery_window_in_days = var.secret_recovery_window_days
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-admin-cert" })
}

resource "aws_secretsmanager_secret_version" "admin_cert" {
  count                    = local.generate_client_admin_cert && var.create_secrets ? 1 : 0
  secret_id                = aws_secretsmanager_secret.admin_cert[0].id
  secret_string_wo         = tls_locally_signed_cert.client_admin[0].cert_pem
  secret_string_wo_version = var.admin_cert_version
}
