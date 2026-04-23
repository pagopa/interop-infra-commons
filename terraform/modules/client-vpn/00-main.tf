terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.app_name
      Environment = var.env
      ManagedBy   = "terraform"
    }
  }
}

locals {
  is_saml             = var.use_saml_auth
  is_mutual_cert      = var.use_mutual_auth
  auth_label          = var.use_saml_auth ? "saml" : "mutual-cert"
  base_name           = format("%s-%s", var.app_name, var.env)
  endpoint_base_name  = format("%s-%s", local.base_name, local.auth_label)
  dns_servers         = var.dns_servers != null ? var.dns_servers : [cidrhost(var.vpc_cidr, 2)]
  subnet_ids_by_index = { for idx, subnet_id in var.subnet_ids : tostring(idx) => subnet_id }
  saml_metadata_xml   = try(trimspace(var.saml_metadata_xml), "")

  server_cert_arn    = var.server_certificate_arn
  client_ca_cert_arn = local.is_mutual_cert ? var.client_ca_certificate_arn : null
  saml_provider_arn  = local.is_saml ? (var.create_saml_provider ? one(aws_iam_saml_provider.idp[*].arn) : var.existing_saml_provider_arn) : null

  security_group_ids = var.create_security_group ? [aws_security_group.vpn[0].id] : var.external_security_group_ids
  log_group_name     = var.connection_log_enabled ? (var.create_log_group ? one(aws_cloudwatch_log_group.vpn[*].name) : var.external_log_group_name) : null

  endpoint_desc = coalesce(var.endpoint_description, "${local.auth_label} auth")
  sg_name       = coalesce(var.security_group_name, "${local.endpoint_base_name}-vpn")
  sg_tag_name   = coalesce(var.security_group_tag_name, "${local.endpoint_base_name}-vpn-sg")
  cw_name       = coalesce(var.log_group_name, "/aws/vpn/${local.endpoint_base_name}")
  cw_tag_name   = coalesce(var.log_group_tag_name, "${local.endpoint_base_name}-vpn-logs")
  endpoint_tag  = coalesce(var.vpn_endpoint_tag_name, "${local.endpoint_base_name}-vpn-endpoint")
  saml_name     = coalesce(var.saml_provider_name, "${local.base_name}-saml-provider")
  saml_tag_name = coalesce(var.saml_provider_tag_name, "${local.base_name}-saml-provider")
  authz_desc    = coalesce(var.authorization_rule_description, local.is_mutual_cert ? "Allow all cert-authenticated clients to access VPC" : (var.saml_group != "" ? "Allow ${var.saml_group} SAML group to access VPC" : "Allow all SAML-authenticated clients to access VPC"))
  authz_cidr    = coalesce(var.authorization_target_network_cidr, var.vpc_cidr)
}

# ─── Checks ──────────────────────────────────────────────────────────────────

check "saml_metadata_xml_required" {
  assert {
    condition     = !local.is_saml || !var.create_saml_provider || local.saml_metadata_xml != ""
    error_message = "saml_metadata_xml must be provided when use_saml_auth is true and create_saml_provider is true."
  }
}

check "existing_saml_provider_required" {
  assert {
    condition     = local.is_saml || var.create_saml_provider
    error_message = "create_saml_provider can be set to false only when use_saml_auth is true."
  }

  assert {
    condition     = var.create_saml_provider || var.existing_saml_provider_arn != null
    error_message = "existing_saml_provider_arn must be provided when create_saml_provider is false."
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

check "server_certificate_arn_required" {
  assert {
    condition     = var.server_certificate_arn != null
    error_message = "server_certificate_arn must be provided."
  }
}

check "client_ca_certificate_arn_constraints" {
  assert {
    condition     = !local.is_mutual_cert || var.client_ca_certificate_arn != null
    error_message = "client_ca_certificate_arn must be provided when use_mutual_auth is true."
  }

  assert {
    condition     = local.is_mutual_cert || var.client_ca_certificate_arn == null
    error_message = "client_ca_certificate_arn can be set only when use_mutual_auth is true."
  }
}

check "network_association_requires_subnets" {
  assert {
    condition     = !var.create_network_associations || length(local.subnet_ids_by_index) > 0
    error_message = "create_network_associations is true but subnet_ids is empty. Provide at least one subnet ID."
  }
}
