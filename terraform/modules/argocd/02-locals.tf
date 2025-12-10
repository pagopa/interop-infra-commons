locals {
  deploy_argocd           = var.env == "dev"
  argocd_repo_server_name = "argocd-repo-server"
  merged_file_name        = "${path.module}/.terraform/merged-values.yaml"

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
  # Usa try() per evitare il ternario che causerebbe type mismatch se merged_values ha dei valori con tipi diversi da default_values_file
  # Se il file mergiato esiste (custom values forniti), lo usa, altrimenti usa il default (secondo argomento di try)
  merged_values = yamldecode(try(data.local_file.merged_values[0].content, local.default_values_file))

  # Final ArgoCD values
  argocd_values = local.merged_values
}
