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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
  }
}

data "aws_caller_identity" "current" {
  count = var.local_testing_mode ? 0 : 1
}

data "aws_region" "current" {
  count = var.local_testing_mode ? 0 : 1
}

data "aws_eks_cluster" "this" {
  count = var.local_testing_mode ? 0 : 1
  name  = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  count = var.local_testing_mode ? 0 : 1
  name  = var.eks_cluster_name
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = var.tags
  }
  
  # Skip validations in local testing mode
  skip_credentials_validation = var.local_testing_mode
  skip_requesting_account_id  = var.local_testing_mode
  skip_metadata_api_check     = var.local_testing_mode
}

provider "kubernetes" {
  # In local testing mode, use kubeconfig; in AWS mode, use EKS credentials
  config_path    = var.local_testing_mode ? "~/.kube/config" : null
  config_context = var.local_testing_mode ? "kind-argocd-test" : null
  host           = !var.local_testing_mode ? data.aws_eks_cluster.this[0].endpoint : null
  cluster_ca_certificate = !var.local_testing_mode ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : null
  token          = !var.local_testing_mode ? data.aws_eks_cluster_auth.this[0].token : null
}

provider "helm" {
  kubernetes {
    config_path    = var.local_testing_mode ? "~/.kube/config" : null
    config_context = var.local_testing_mode ? "kind-argocd-test" : null
    host           = !var.local_testing_mode ? data.aws_eks_cluster.this[0].endpoint : null
    cluster_ca_certificate = !var.local_testing_mode ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : null
    token          = !var.local_testing_mode ? data.aws_eks_cluster_auth.this[0].token : null
  }
}

provider "kubectl" {
  config_path      = var.local_testing_mode ? "~/.kube/config" : null
  config_context   = var.local_testing_mode ? "kind-argocd-test" : null
  host             = !var.local_testing_mode ? data.aws_eks_cluster.this[0].endpoint : null
  cluster_ca_certificate = !var.local_testing_mode ? base64decode(data.aws_eks_cluster.this[0].certificate_authority[0].data) : null
  token            = !var.local_testing_mode ? data.aws_eks_cluster_auth.this[0].token : null
  load_config_file = var.local_testing_mode
}