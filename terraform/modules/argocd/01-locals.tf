locals {
  deploy_argocd           = var.env == "dev"
  argocd_repo_server_name = "argocd-repo-server"

  # Costruisce le immagini complete gestendo il prefix vuoto
  microservices_plugin_image = var.microservices_plugin_image_prefix != "" ? "${var.microservices_plugin_image_prefix}/${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}" : "${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}"
  cronjobs_plugin_image      = var.cronjobs_plugin_image_prefix != "" ? "${var.cronjobs_plugin_image_prefix}/${var.cronjobs_plugin_image_name}:${var.cronjobs_plugin_image_tag}" : "${var.cronjobs_plugin_image_name}:${var.cronjobs_plugin_image_tag}"

  # Usa solo i defaults - gli override vengono applicati tramite blocchi set{}
  argocd_values = yamldecode(templatefile("${path.module}/values/argocd-cm-values.yaml", {
    microservices_plugin_name  = var.microservices_plugin_name
    microservices_plugin_image = local.microservices_plugin_image
    cronjobs_plugin_name       = var.cronjobs_plugin_name
    cronjobs_plugin_image      = local.cronjobs_plugin_image
  }))
}
