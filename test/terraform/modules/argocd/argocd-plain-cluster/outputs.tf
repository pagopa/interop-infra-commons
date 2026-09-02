output "argocd_namespace" {
  value       = var.argocd_namespace
  description = "The namespace where ArgoCD is deployed"
}

output "argocd_server_url" {
  value       = var.deploy_argocd ? module.argocd.argocd_server_url : null
  description = "The URL of the ArgoCD server (from module output)"
}

output "argocd_admin_username" {
  value       = "admin"
  description = "The admin username for ArgoCD"
}

output "argocd_admin_password" {
  value       = random_password.argocd_admin.result
  description = "The admin password for ArgoCD (plain text)"
  sensitive   = true
}

output "argocd_admin_bcrypt_password" {
  value       = bcrypt(random_password.argocd_admin.result)
  description = "The admin password for ArgoCD (bcrypt hash)"
  sensitive   = true
}

output "module_outputs" {
  value       = var.deploy_argocd ? module.argocd : null
  description = "All outputs from the ArgoCD module"
  sensitive   = true
}
