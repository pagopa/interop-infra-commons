terraform {
  required_version = "~> 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}
