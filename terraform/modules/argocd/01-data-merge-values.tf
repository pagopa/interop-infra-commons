# Terraform data per il deep merge dei values YAML usando yq
# Esegue lo script merge-values.sh che utilizza yq per fare il merge dei file YAML
resource "terraform_data" "merge_argocd_values" {
  count = local.should_merge_custom_values ? 1 : 0

  # triggers_replace forza l'esecuzione del provisioner quando i file di input cambiano (sia creazione che update)
  # Quando uno dei file cambia, Terraform distrugge e ricrea la risorsa terraform_data rieseguendo il provisioner
  triggers_replace = {
    base_file_hash     = md5(local.default_values_file)
    override_file_hash = var.argocd_custom_values != null ? filemd5(var.argocd_custom_values) : ""
  }

  input = {
    base_file_content = local.default_values_file
    override_file     = var.argocd_custom_values
  }

  provisioner "local-exec" {
    command = "${path.module}/scripts/merge-values.sh > ${local.merged_file_name}"

    environment = {
      MODULE_PATH   = path.module
      BASE_FILE     = base64encode(self.input.base_file_content)
      OVERRIDE_FILE = self.input.override_file
    }
  }
}

# Data source per leggere il file generato dal terraform_data
data "local_file" "merged_values" {
  count    = local.should_merge_custom_values ? 1 : 0
  filename = local.merged_file_name

  depends_on = [terraform_data.merge_argocd_values]
}

