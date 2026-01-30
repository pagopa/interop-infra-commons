# Data source per il service ArgoCD creato da Helm
data "kubernetes_service_v1" "argocd_server" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    name      = "argocd-server"
    namespace = local.argocd_namespace
  }

  depends_on = [helm_release.argocd]
}

locals {
  argocd_server_url = var.deploy_argocd ? "https://${data.kubernetes_service_v1.argocd_server[0].metadata[0].name}.${local.argocd_namespace}.svc.cluster.local" : null
}

output "argocd_server_url" {
  value       = local.argocd_server_url
  description = "The URL of the ArgoCD server"
}

output "argocd_admin_credentials" {
  value       = kubernetes_secret_v1.argocd_admin_credentials[0].data
  description = "The admin credentials for ArgoCD"
  sensitive   = true
}

# ALB outputs (if enabled)
#output "argocd_alb_dns_name" {
#  value       = var.create_argocd_alb && var.deploy_argocd ? aws_lb.argocd[0].dns_name : null
#  description = "DNS name of the ArgoCD ALB"
#}
#
#output "argocd_alb_zone_id" {
#  value       = var.create_argocd_alb && var.deploy_argocd ? aws_lb.argocd[0].zone_id : null
#  description = "Zone ID of the ArgoCD ALB"
#}
#
#output "argocd_domain" {
#  value       = var.argocd_domain
#  description = "Configured domain for ArgoCD"
#}
#
#output "argocd_url" {
#  value       = var.argocd_domain != null ? "https://${var.argocd_domain}" : null
#  description = "Full HTTPS URL to access ArgoCD"
#}
#
#output "argocd_route53_zone_id" {
#  value       = local.create_route53_record ? local.route53_zone_id_resolved : null
#  description = "Route53 zone ID used for DNS record"
#}