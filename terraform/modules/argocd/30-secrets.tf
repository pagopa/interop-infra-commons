resource "aws_secretsmanager_secret" "argocd_admin_credentials" {
  count = var.deploy_argocd && var.argocd_admin_bcrypt_password == "" ? 1 : 0

  name                    = "${var.secret_prefix}users/admin"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.secret_tags
}

data "aws_secretsmanager_random_password" "argocd_admin" {
  count = var.deploy_argocd && var.argocd_admin_bcrypt_password == "" ? 1 : 0

  password_length            = 30
  require_each_included_type = true
  exclude_numbers            = false
  exclude_punctuation        = true
  include_space              = false
}

resource "aws_secretsmanager_secret_version" "argocd_admin_credentials" {
  count = var.deploy_argocd && var.argocd_admin_bcrypt_password == "" ? 1 : 0

  secret_id = aws_secretsmanager_secret.argocd_admin_credentials[0].id

  secret_string = jsonencode({
    username        = "admin"
    password        = data.aws_secretsmanager_random_password.argocd_admin[0].random_password
    bcrypt_password = bcrypt(data.aws_secretsmanager_random_password.argocd_admin[0].random_password)
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

resource "time_static" "argocd_admin_credentials_update" {
  count = var.deploy_argocd && var.argocd_admin_bcrypt_password == "" ? 1 : 0

  triggers = {
    secret_string = aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string
  }
}

resource "kubernetes_secret_v1" "argocd_admin_credentials" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    namespace   = local.argocd_namespace
    name        = "argocd-admin-user"
    annotations = var.argocd_admin_bcrypt_password == "" ? {
      "infra.interop.pagopa.it/aws-secretsmanager-secret-id" : aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_id,
      "infra.interop.pagopa.it/aws-secretsmanager-version-id" : aws_secretsmanager_secret_version.argocd_admin_credentials[0].version_id,
      "infra.interop.pagopa.it/updated-at" : time_static.argocd_admin_credentials_update[0].rfc3339
    } : {
      "infra.interop.pagopa.it/updated-at" : var.argocd_admin_password_mtime
    }
  }

  data = var.argocd_admin_bcrypt_password == "" ? {
    for key, value in jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string) : key => value
  } : {
    username        = "admin"
    password        = "[overridden]"
    bcrypt_password = var.argocd_admin_bcrypt_password
  }

  depends_on = [kubernetes_namespace_v1.argocd]
}