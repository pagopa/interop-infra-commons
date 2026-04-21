terraform {
  required_version = "~> 1.8.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.13.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5.0"
    }
  }
}


# Provider per kind cluster locale o cluster AWS remoto
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = var.kubernetes_config_context
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = var.kubernetes_config_context
  }
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



# Note: Il namespace viene creato dal modulo ArgoCD
# Non è necessario crearlo qui per evitare conflitti

# Null resource per build e load immagini plugin PRIMA del modulo
resource "null_resource" "build_and_load_plugin_images" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      REPO_ROOT="${path.module}/../../../../../"
      
      #echo "Building plugin images..."
      #docker build -f "$REPO_ROOT/argocd/plugins/cronjobs/Dockerfile" \
      #  -t argocd-plugin-cronjobs:local "$REPO_ROOT"
      
      #docker build -f "$REPO_ROOT/argocd/plugins/microservices/Dockerfile" \
      #  -t argocd-plugin-microservices:local "$REPO_ROOT"
      
      #echo "Loading images into kind cluster..."
      #kind load docker-image argocd-plugin-cronjobs:local --name argocd-test
      #kind load docker-image argocd-plugin-microservices:local --name argocd-test
      
      #echo "Plugin images ready"
    EOT
  }

  triggers = {
    # Rebuild se cambiano i Dockerfile
    cronjobs_dockerfile      = filemd5("${path.module}/../../../../../argocd/plugins/cronjobs/Dockerfile")
    microservices_dockerfile = filemd5("${path.module}/../../../../../argocd/plugins/microservices/Dockerfile")
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

  # Configurazione ArgoCD
  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  argocd_custom_values = "${path.module}/argocd-cm-values-plain.yaml"
  deploy_argocd        = var.deploy_argocd

  # Credenziali repo (mock values)
  argocd_app_repo_username = var.argocd_app_repo_username
  argocd_app_repo_password = var.argocd_app_repo_password

  # Disabilita ALB/Route53 per modalità locale (questo attiva automaticamente is_local_testing)
  create_argocd_alb          = false
  create_private_hosted_zone = false

  # Override credenziali admin per evitare AWS Secrets Manager
  # Usa bcrypt_hash da random_password (memorizzato nello stato)
  argocd_admin_bcrypt_password = random_password.argocd_admin.bcrypt_hash
  argocd_admin_password_mtime  = time_static.test_timestamp.rfc3339

  # Nota: Le immagini plugin vengono costruite e caricate da null_resource
  # prima del modulo grazie all'ordine di definizione (null_resource qui sopra)

  resource_prefix = "argocd-test"
}
