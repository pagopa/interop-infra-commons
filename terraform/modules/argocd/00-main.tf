terraform {
  required_version = "~> 1.8.0"

  backend "s3" {}

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.2"
    }
    argocd = {
      source  = "argoproj-labs/argocd"
      version = "7.11.2"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#data "aws_eks_cluster" "this" {
#  name = var.eks_cluster_name
#}
#
#data "aws_eks_cluster_auth" "this" {
#  name = var.eks_cluster_name
#}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
}

#provider "kubernetes" {
#  host                   = data.aws_eks_cluster.this.endpoint
#  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#  token                  = data.aws_eks_cluster_auth.this.token
#}

#provider "helm" {
#  kubernetes {
#    host                   = data.aws_eks_cluster.this.endpoint
#    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#    token                  = data.aws_eks_cluster_auth.this.token
#  }
#}