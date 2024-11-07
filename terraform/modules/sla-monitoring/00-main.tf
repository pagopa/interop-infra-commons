terraform {

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}