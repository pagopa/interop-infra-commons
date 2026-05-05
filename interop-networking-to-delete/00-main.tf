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

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  resolved_vpc_id     = var.create_networking_resources ? aws_vpc.main[0].id : var.vpn_vpc_id
  endpoint_subnet_ids = length(var.subnet_ids) > 0 ? var.subnet_ids : (var.create_networking_resources ? [aws_subnet.main[0].id] : [])
}

check "external_vpc_id_required" {
  assert {
    condition     = var.create_networking_resources || var.vpn_vpc_id != null
    error_message = "vpn_vpc_id must be provided when create_networking_resources is false."
  }
}
