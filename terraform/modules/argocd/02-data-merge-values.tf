# Terraform data per il deep merge dei values YAML usando yq
# Esegue lo script merge-values.sh che utilizza yq per fare il merge dei file YAML
resource "terraform_data" "merge_argocd_values" {
  count = local.should_merge_custom_values ? 1 : 0

  input = {
    base_file_content = local.default_values_file
    override_file     = var.argocd_custom_values
    trigger           = var.argocd_custom_values != null ? filemd5(var.argocd_custom_values) : ""
  }

  provisioner "local-exec" {
    when    = create
    command = "${path.module}/scripts/merge-values.sh > ${locals.merged_file_name}"
    
    environment = {
      # base64 per evitare problemi con caratteri speciali e multilinea
      BASE_FILE     = base64encode(self.input.base_file_content)
      OVERRIDE_FILE = self.input.override_file
    }
  }
}

