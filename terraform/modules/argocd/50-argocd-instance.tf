# Create ArgoCD namespace
resource "kubernetes_namespace_v1" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd[0].metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode(local.argocd_values)
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_bcrypt_password != null ? var.argocd_admin_bcrypt_password : jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string).bcrypt_password
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = var.argocd_admin_password_mtime != null ? var.argocd_admin_password_mtime : time_static.argocd_admin_credentials_update[0].rfc3339
  }

  set {
    name  = "crds.install"
    value = "true"
  }

  # Explicit dependency on the merged file (when present)
  # This ensures that the provisioner runs before reading the file
  depends_on = [
    data.local_file.merged_values
  ]
}