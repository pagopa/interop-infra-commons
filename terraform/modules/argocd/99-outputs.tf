# Data source per il service ArgoCD creato da Helm
data "kubernetes_service_v1" "argocd_server" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    name      = "argocd-server"
    namespace = kubernetes_namespace_v1.argocd[0].metadata[0].name
  }

  depends_on = [helm_release.argocd]
}

locals {
  argocd_server_url = var.deploy_argocd ? "https://${data.kubernetes_service_v1.argocd_server[0].metadata[0].name}.${kubernetes_namespace_v1.argocd[0].metadata[0].name}.svc.cluster.local" : null
}

output "argocd_server_url" {
  value       = local.argocd_server_url
  description = "The URL of the ArgoCD server"
}

output "argocd_admin_credentials" {
  value       = kubernetes_secret_v1.argocd_admin_credentials[0].data
  description = "The admin credentials for ArgoCD"
}