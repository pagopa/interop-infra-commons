
terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.1"
    }
  }
}

locals {
  is_mutual_cert       = var.vpn_type == "mutual-cert"
  is_saml              = var.vpn_type == "saml"
  name_prefix          = var.name_prefix_override != null ? var.name_prefix_override : format("%s-%s", var.app_name, var.env)
  endpoint_name_prefix = var.endpoint_name_prefix_override != null ? var.endpoint_name_prefix_override : format("%s-%s", local.name_prefix, var.vpn_type)
  dns_servers          = var.dns_servers != null ? var.dns_servers : [cidrhost(var.vpc_cidr, 2)]
  subnet_ids_by_index  = { for idx, subnet_id in var.subnet_ids : tostring(idx) => subnet_id }

  # PKI: usa risorse esterne se fornite, altrimenti quelle create internamente
  create_server_pki           = var.external_server_certificate_arn == null
  create_client_pki           = local.is_mutual_cert && var.external_client_ca_certificate_arn == null
  use_external_client_signing = local.is_mutual_cert && var.external_client_ca_cert_pem != null && var.external_client_ca_private_key_pem != null
  generate_client_admin_cert  = local.is_mutual_cert && (local.create_client_pki || local.use_external_client_signing)
  server_cert_arn             = local.create_server_pki ? one(aws_acm_certificate.vpn_server[*].arn) : var.external_server_certificate_arn
  client_ca_cert_arn          = local.is_mutual_cert ? (local.create_client_pki ? one(aws_acm_certificate.client_ca[*].arn) : var.external_client_ca_certificate_arn) : null
  client_ca_cert_pem_for_signing = local.use_external_client_signing ? var.external_client_ca_cert_pem : (
    local.create_client_pki ? one(tls_self_signed_cert.client_ca[*].cert_pem) : null
  )
  client_ca_private_key_pem_for_signing = local.use_external_client_signing ? var.external_client_ca_private_key_pem : (
    local.create_client_pki ? one(tls_private_key.client_ca[*].private_key_pem) : null
  )
  saml_provider_arn = local.is_saml ? (var.create_saml_provider ? one(aws_iam_saml_provider.idp[*].arn) : var.external_saml_provider_arn) : null

  # Security group: usa quello creato internamente o quelli passati dall'esterno
  security_group_ids = var.create_security_group ? [aws_security_group.vpn[0].id] : var.external_security_group_ids

  # Log group: usa quello creato internamente o il nome passato dall'esterno
  log_group_name = var.create_log_group ? one(aws_cloudwatch_log_group.vpn[*].name) : var.external_log_group_name

  # Endpoint and rule customization
  resolved_endpoint_description     = var.endpoint_description != null ? var.endpoint_description : "${local.endpoint_name_prefix}: ${var.vpn_type} auth"
  resolved_security_group_name      = var.security_group_name != null ? var.security_group_name : "${local.endpoint_name_prefix}-vpn"
  resolved_log_group_name           = var.log_group_name != null ? var.log_group_name : "/aws/vpn/${local.endpoint_name_prefix}"
  authorization_target_network_cidr = var.authorization_target_network_cidr != null ? var.authorization_target_network_cidr : var.vpc_cidr
  resolved_saml_provider_name       = var.saml_provider_name != null ? var.saml_provider_name : "${local.name_prefix}-saml-provider"
  resolved_saml_authorization_rule_desc = var.saml_authorization_rule_description != null ? var.saml_authorization_rule_description : (
    var.saml_group != "" ? "Allow ${var.saml_group} SAML group to access VPC" : "Allow all SAML-authenticated clients to access VPC"
  )

  # Secrets Manager: prefisso path
  secret_prefix = var.secret_name_prefix != null ? var.secret_name_prefix : "${local.name_prefix}/vpn"

  # PKI naming
  server_ca_cn    = var.server_ca_common_name != null ? var.server_ca_common_name : "${local.name_prefix}.server.ca"
  server_cn       = var.server_common_name != null ? var.server_common_name : "${local.name_prefix}.server"
  client_ca_cn    = var.client_ca_common_name != null ? var.client_ca_common_name : "${local.name_prefix}.client.ca"
  client_admin_cn = var.client_admin_common_name != null ? var.client_admin_common_name : "${local.name_prefix}.client.admin"
}

check "saml_metadata_xml_required" {
  assert {
    condition     = !local.is_saml || !var.create_saml_provider || trimspace(var.saml_metadata_xml) != ""
    error_message = "saml_metadata_xml must be provided when vpn_type is 'saml' and create_saml_provider is true."
  }
}

check "external_saml_provider_required" {
  assert {
    condition     = local.is_saml || var.create_saml_provider
    error_message = "create_saml_provider can be set to false only when vpn_type is 'saml'."
  }

  assert {
    condition     = var.create_saml_provider || var.external_saml_provider_arn != null
    error_message = "external_saml_provider_arn must be provided when create_saml_provider is false."
  }
}

check "external_security_group_ids_required" {
  assert {
    condition     = var.create_security_group || length(var.external_security_group_ids) > 0
    error_message = "external_security_group_ids must be provided when create_security_group is false."
  }
}

check "external_log_group_name_required" {
  assert {
    condition     = var.create_log_group || !var.connection_log_enabled || var.external_log_group_name != null
    error_message = "external_log_group_name must be provided when create_log_group is false and connection_log_enabled is true."
  }
}

check "external_client_ca_for_mutual_cert_only" {
  assert {
    condition     = local.is_mutual_cert || var.external_client_ca_certificate_arn == null
    error_message = "external_client_ca_certificate_arn can be set only when vpn_type is 'mutual-cert'."
  }
}

check "external_client_ca_signing_pair" {
  assert {
    condition = (
      (var.external_client_ca_cert_pem == null && var.external_client_ca_private_key_pem == null) ||
      (var.external_client_ca_cert_pem != null && var.external_client_ca_private_key_pem != null)
    )
    error_message = "external_client_ca_cert_pem and external_client_ca_private_key_pem must be provided together."
  }

  assert {
    condition     = !local.use_external_client_signing || var.external_client_ca_certificate_arn != null
    error_message = "external_client_ca_certificate_arn must be provided when external client CA signing PEMs are used."
  }

  assert {
    condition     = local.is_mutual_cert || (var.external_client_ca_cert_pem == null && var.external_client_ca_private_key_pem == null)
    error_message = "external_client_ca_cert_pem and external_client_ca_private_key_pem can be set only when vpn_type is 'mutual-cert'."
  }
}
