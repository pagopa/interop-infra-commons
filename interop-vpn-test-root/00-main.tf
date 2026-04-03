terraform {
  required_version = ">= 1.11.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.88"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.0"
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

data "aws_availability_zones" "available" {
  state = "available"
}

data "http" "saml_metadata" {
  count = local.is_saml && var.saml_metadata_xml == "" && var.saml_metadata_url != null ? 1 : 0
  url   = var.saml_metadata_url
}

locals {
  is_saml = var.vpn_type == "saml"

  resolved_vpc_id     = var.create_test_network ? aws_vpc.main[0].id : var.vpn_vpc_id
  endpoint_subnet_ids = !var.create_network_associations ? [] : (
    length(var.subnet_ids) > 0 ? var.subnet_ids : (var.create_test_network ? [aws_subnet.main[0].id] : [])
  )

  saml_metadata_xml = var.saml_metadata_xml != "" ? var.saml_metadata_xml : (
    local.is_saml && var.saml_metadata_url != null ? data.http.saml_metadata[0].response_body : null
  )
}

check "external_vpc_id_required" {
  assert {
    condition     = var.create_test_network || var.vpn_vpc_id != null
    error_message = "vpn_vpc_id must be provided when create_test_network is false."
  }
}
