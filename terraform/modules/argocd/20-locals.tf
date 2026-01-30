locals {
  deploy_argocd           = var.env == "dev"
  argocd_repo_server_name = "argocd-repo-server"
  merged_file_name        = "${path.module}/.terraform/merged-values.yaml"
  argocd_namespace        = var.deploy_argocd_namespace ? kubernetes_namespace_v1.argocd[0].metadata[0].name : data.kubernetes_namespace_v1.argocd[0].metadata[0].name

  # Default values ​​template file (processed with plugin variables)
  default_values_file = templatefile("${path.module}/values/argocd-cm-values.yaml", {})

  # Determines whether to merge with custom files
  should_merge_custom_values = var.argocd_custom_values != null && var.argocd_custom_values != ""

  # Merge values: base + custom (if provided)
  # Use try() to avoid the ternary that would cause type mismatch if merged_values ​​has values ​​with types other than default_values_file
  # If the merged file exists (custom values ​​provided), use it; otherwise, use the default (second argument to try)
  merged_values = yamldecode(try(data.local_file.merged_values[0].content, local.default_values_file))

  # Final ArgoCD values
  argocd_values = local.merged_values
}
