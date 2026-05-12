terraform {
  required_version = "~> 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

resource "terraform_data" "validate_api_stage" {
  lifecycle {
    precondition {
      condition     = var.apigw_single_endpoint_name == "" || var.api_stage != ""
      error_message = "Please provide a value for api_stage if apigw_single_endpoint_name is not empty."
    }
  }
}
