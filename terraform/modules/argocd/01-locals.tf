locals {
  deploy_argocd           = var.env == "dev"
  argocd_repo_server_name = "argocd-repo-server"
  merged_file_name = "${path.module}/.terraform/merged-values.yaml"

  # Costruisce le immagini complete gestendo il prefix vuoto
  microservices_plugin_image = var.microservices_plugin_image_prefix != "" ? "${var.microservices_plugin_image_prefix}/${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}" : "${var.microservices_plugin_image_name}:${var.microservices_plugin_image_tag}"
  cronjobs_plugin_image      = var.cronjobs_plugin_image_prefix != "" ? "${var.cronjobs_plugin_image_prefix}/${var.cronjobs_plugin_image_name}:${var.cronjobs_plugin_image_tag}" : "${var.cronjobs_plugin_image_name}:${var.cronjobs_plugin_image_tag}"

  # Template file dei valori di default (processato con variabili plugin)
  default_values_file = templatefile("${path.module}/values/argocd-cm-values.yaml", {
    microservices_plugin_name  = var.microservices_plugin_name
    microservices_plugin_image = local.microservices_plugin_image
    cronjobs_plugin_name       = var.cronjobs_plugin_name
    cronjobs_plugin_image      = local.cronjobs_plugin_image
  })

  # Determina se mergiare con file custom
  should_merge_custom_values = var.argocd_custom_values != null && var.argocd_custom_values != ""

  # Merge dei values: base + custom (se forniti)
  # Sfrutta terraform_data per eseguire lo script yq che fa il deep merge
  # Il risultato viene letto dal file generato dopo l'esecuzione del provisioner
  merged_values_json = local.should_merge_custom_values ? yamldecode(file("${path.module}/.terraform/merged-values.yaml")) : yamldecode(local.default_values_file)

  # Final ArgoCD values
  argocd_values = local.merged_values_json
}
