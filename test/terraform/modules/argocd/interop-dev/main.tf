terraform {
  required_version = "~> 1.8.0"

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
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}

# Data sources per EKS cluster
data "aws_eks_cluster" "this" {
  name = var.eks_cluster_name
}

data "aws_eks_cluster_auth" "this" {
  name = var.eks_cluster_name
}

# Provider AWS
provider "aws" {
  region = var.aws_region
}

# Provider Kubernetes usando EKS
provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

# Provider Helm usando EKS
provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Provider kubectl usando EKS
provider "kubectl" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
  load_config_file       = false
}

# Genera password casuale locale per admin
resource "random_password" "argocd_admin" {
  length  = 30
  special = false
  numeric = true
  upper   = true
  lower   = true

  keepers = {
    # Mantiene la password stabile finché il seed non cambia
    seed = var.password_seed
  }
}

resource "time_static" "test_timestamp" {
  triggers = {
    seed = "argocd-test-initial"
  }
}


# Usa il modulo ArgoCD
module "argocd" {
  source = "../../../../../terraform/modules/argocd" # Punta a terraform/modules/argocd

  # Variabili richieste dal modulo
  aws_region       = var.aws_region
  env              = var.env
  tags             = var.tags
  eks_cluster_name = var.eks_cluster_name
  resource_prefix  = var.resource_prefix

  # Non siamo in local testing - usa EKS
  is_local_testing = false

  # Configurazione ArgoCD
  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  argocd_custom_values = "${path.module}/custom-values.yaml"
  deploy_argocd        = var.deploy_argocd

  # Credenziali repo (mock values)
  argocd_app_repo_username = var.argocd_app_repo_username
  argocd_app_repo_password = var.argocd_app_repo_password

  # Disabilita ALB/Route53 per deployment senza load balancer
  #create_argocd_alb          = false
  #create_private_hosted_zone = false

  # Abilita ALB/Route53
  create_argocd_alb          = true
  create_private_hosted_zone = true
  public_hosted_zone_name = "interop-dev.pagopa.it"
  argocd_subdomain        = "dev-experimental-argocd"
  vpn_clients_security_group_id = "sg-0bb1c123456789abc"
  private_subnet_ids = [
    "subnet-0bb1c123456789abc",
    "subnet-0cc1c123456789abc"
  ]

  # Abilita creazione ArgoCD Project e RBAC
  create_argocd_project = var.create_argocd_project
  create_argocd_rbac    = var.create_argocd_rbac

  # Non usare AWS Secrets Manager, usa password fornita localmente
  use_aws_secrets_manager      = false
  argocd_admin_bcrypt_password = random_password.argocd_admin.bcrypt_hash
  argocd_admin_password_mtime  = time_static.test_timestamp.rfc3339

  microservices_plugin_name         = "argocd-plugin-microservices"
  microservices_plugin_image_prefix = "505630707203.dkr.ecr.eu-south-1.amazonaws.com"
  microservices_plugin_image_name   = "argocd-plugin-microservices"
  microservices_plugin_image_tag    = "latest"


  cronjobs_plugin_name         = "argocd-plugin-cronjobs"
  cronjobs_plugin_image_prefix = "505630707203.dkr.ecr.eu-south-1.amazonaws.com"
  cronjobs_plugin_image_name   = "argocd-plugin-cronjobs"
  cronjobs_plugin_image_tag    = "latest"


  argocd_repository_url      = "https://github.com/pagopa/interop-core-deployment.git"
  argocd_repository_username = "***REMOVED***"
  argocd_repository_password = "***REMOVED***"

}
