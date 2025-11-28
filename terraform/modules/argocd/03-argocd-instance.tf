resource "helm_release" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  name       = "argocd"
  namespace  = var.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    merge(
      yamldecode(file("${path.module}/defaults/argocd-cm-values.yaml")),
      var.argocd_custom_values != null ? yamldecode(file(var.argocd_custom_values)) : {}
    )
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string).bcrypt_password
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = time_static.argocd_admin_credentials_update[0].rfc3339
  }
}