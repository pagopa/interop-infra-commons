terraform {
  required_version = "~> 1.8.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.11.2"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}
