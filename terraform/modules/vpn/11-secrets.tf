resource "aws_secretsmanager_secret" "admin_key" {
  count                   = local.create_client_pki && var.create_secrets ? 1 : 0
  name                    = "${local.secret_prefix}/admin-client-key"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-admin-key" })
}


# tls_private_key.client_admin rimane nello state Terraform (sensitive) perché
# tls_locally_signed_cert.private_key_pem non supporta valori ephemeral
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/locally_signed_cert#private_key_pem
#
# repro write-only:
# ephemeral "tls_private_key" "client_admin" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }
# secret_string_wo = ephemeral.tls_private_key.client_admin.private_key_pem
resource "aws_secretsmanager_secret_version" "admin_key" {
  count                    = local.create_client_pki && var.create_secrets ? 1 : 0
  secret_id                = aws_secretsmanager_secret.admin_key[0].id
  secret_string_wo         = tls_private_key.client_admin[0].private_key_pem
  secret_string_wo_version = var.admin_key_version
}

resource "aws_secretsmanager_secret" "admin_cert" {
  count                   = local.create_client_pki && var.create_secrets ? 1 : 0
  name                    = "${local.secret_prefix}/admin-client-cert"
  recovery_window_in_days = 7
  tags                    = merge(var.tags, { Name = "${local.name_prefix}-admin-cert" })
}

# il certificato pubblico usa secret_string normale (si può anche usare secret_string_wo + secret_string_wo_version)
resource "aws_secretsmanager_secret_version" "admin_cert" {
  count                    = local.create_client_pki && var.create_secrets ? 1 : 0
  secret_id                = aws_secretsmanager_secret.admin_cert[0].id
  secret_string_wo         = tls_locally_signed_cert.client_admin[0].cert_pem
  secret_string_wo_version = var.admin_cert_version
}
