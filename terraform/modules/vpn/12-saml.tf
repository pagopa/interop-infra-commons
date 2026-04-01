
locals {
  saml_metadata = local.is_saml ? replace(
    coalesce(var.saml_metadata_xml, ""),
    "WantAuthnRequestsSigned=\"true\"",
    "WantAuthnRequestsSigned=\"false\""
  ) : null
}

resource "aws_iam_saml_provider" "idp" {
  count                  = local.is_saml && var.create_saml_provider ? 1 : 0
  name                   = local.resolved_saml_provider_name
  saml_metadata_document = local.saml_metadata
  tags                   = merge(var.tags, { Name = "${local.name_prefix}-saml-provider" })
}
