# ArgoCD Repository per il repository applicativo
resource "kubectl_manifest" "argocd_repository" {
  count = var.deploy_argocd && var.create_argocd_repository ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "v1"
    kind       = "Secret"
    metadata = {
      name      = var.argocd_repository_secret_name
      namespace = local.argocd_namespace
      labels = {
        "argocd.argoproj.io/secret-type" = "repository"
      }
    }
    type = "Opaque"
    stringData = {
      type          = var.argocd_repository_type
      url           = var.argocd_repository_url
      password      = var.argocd_repository_password != "" ? var.argocd_repository_password : null
      username      = var.argocd_repository_username != "" ? var.argocd_repository_username : null
      sshPrivateKey = var.argocd_repository_ssh_private_key != "" ? var.argocd_repository_ssh_private_key : null
      insecure      = var.argocd_repository_insecure ? "true" : "false"
      enableLFS     = var.argocd_repository_enable_lfs ? "true" : "false"
    }
  })

  depends_on = [helm_release.argocd]
}