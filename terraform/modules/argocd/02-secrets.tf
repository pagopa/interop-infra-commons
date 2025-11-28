resource "aws_secretsmanager_secret" "argocd_admin_credentials" {
  count = var.deploy_argocd ? 1 : 0

  name = "k8s/argocd/users/admin"
}

data "aws_secretsmanager_random_password" "argocd_admin" {
  count = var.deploy_argocd ? 1 : 0

  password_length            = 30
  require_each_included_type = true
  exclude_numbers            = false
  exclude_punctuation        = true
  include_space              = false
}

resource "aws_secretsmanager_secret_version" "argocd_admin_credentials" {
  count = var.deploy_argocd ? 1 : 0

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
  count = var.deploy_argocd ? 1 : 0

  triggers = {
    secret_string = aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string
  }
}

resource "kubernetes_secret_v1" "argocd_admin_credentials" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    namespace = var.argocd_namespace
    name      = "argocd-admin-user"
    annotations = {
      "infra.interop.pagopa.it/aws-secretsmanager-secret-id" : aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_id,
      "infra.interop.pagopa.it/aws-secretsmanager-version-id" : aws_secretsmanager_secret_version.argocd_admin_credentials[0].version_id,
      "infra.interop.pagopa.it/updated-at" : time_static.argocd_admin_credentials_update[0].rfc3339
    }
  }

  data = {
    for key, value in jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string) : key => value
  }
}