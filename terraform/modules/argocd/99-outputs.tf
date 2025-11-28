locals {
  argocd_server_url = "https://${kubernetes_service.argocd_server[0].metadata[0].name}.${kubernetes_namespace_v1.argocd[0].metadata[0].name}.svc.cluster.local"
}

output "argocd_server_url" {
  value = local.argocd_server_url
  description = "The URL of the ArgoCD server"
}

output "argocd_admin_credentials" {
  value = kubernetes_secret_v1.argocd_admin_credentials[0].data
  description = "The admin credentials for ArgoCD"
}