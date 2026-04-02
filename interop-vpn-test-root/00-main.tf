
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

# Solo per test locale quando keycloak è esposto tramite ngrok - da rimuovere
data "http" "ngrok_api" {
  count = local.is_saml && var.keycloak_realm != "" ? 1 : 0
  url   = "http://localhost:4040/api/tunnels"
}

data "http" "keycloak_saml_metadata" {
  count = local.is_saml && var.keycloak_realm != "" ? 1 : 0
  url   = "${local.keycloak_base_url}/realms/${var.keycloak_realm}/protocol/saml/descriptor"
}

locals {
  is_saml = var.enable_saml_vpn || var.keycloak_realm != "" || var.saml_metadata_xml != ""

  resolved_vpc_id = var.create_test_network ? aws_vpc.main[0].id : var.vpn_vpc_id
  mutual_cert_subnet_ids = var.mutual_cert_subnet_ids
  saml_subnet_ids        = var.saml_subnet_ids
# Solo per test locale quando keycloak è esposto tramite ngrok - da rimuovere
  ngrok_tunnels     = local.is_saml && var.keycloak_realm != "" ? jsondecode(data.http.ngrok_api[0].response_body).tunnels : []
  keycloak_base_url = local.is_saml && var.keycloak_realm != "" ? [for t in local.ngrok_tunnels : t.public_url if startswith(t.public_url, "https")][0] : null


  # a regime Keycloak esposto tramite ALB, questo test invece è basato su ngrok
  # non serve: bisogna inserire `saml_metadata_xml` di keycloak
  saml_metadata_xml = var.saml_metadata_xml != "" ? var.saml_metadata_xml : local.is_saml ? data.http.keycloak_saml_metadata[0].response_body : null
}

check "external_vpc_id_required" {
  assert {
    condition     = var.create_test_network || var.vpn_vpc_id != null
    error_message = "vpn_vpc_id must be provided when create_test_network is false."
  }
}
