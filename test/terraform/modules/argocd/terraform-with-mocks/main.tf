terraform {
  required_version = "~> 1.8.0"

  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.18.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.9.0"
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

# Provider per kind cluster locale
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-argocd-test"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    config_context = "kind-argocd-test"
  }
}

# Genera password casuale locale per admin
resource "random_password" "argocd_admin" {
  length  = 30
  special = false
  numeric = true
  upper   = true
  lower   = true
}

# Note: Il namespace viene creato dal modulo ArgoCD
# Non è necessario crearlo qui per evitare conflitti

# Null resource per build e load immagini plugin PRIMA del modulo
resource "null_resource" "build_and_load_plugin_images" {
  provisioner "local-exec" {
    command = <<-EOT
      set -e
      REPO_ROOT="${path.module}/../../../../../"
      
      echo "Building plugin images..."
      docker build -f "$REPO_ROOT/argocd/plugins/cronjobs/Dockerfile" \
        -t argocd-plugin-cronjobs:local "$REPO_ROOT"
      
      docker build -f "$REPO_ROOT/argocd/plugins/microservices/Dockerfile" \
        -t argocd-plugin-microservices:local "$REPO_ROOT"
      
      echo "Loading images into kind cluster..."
      kind load docker-image argocd-plugin-cronjobs:local --name argocd-test
      kind load docker-image argocd-plugin-microservices:local --name argocd-test
      
      echo "Plugin images ready"
    EOT
  }

  triggers = {
    # Rebuild se cambiano i Dockerfile
    cronjobs_dockerfile      = filemd5("${path.module}/../../../../../argocd/plugins/cronjobs/Dockerfile")
    microservices_dockerfile = filemd5("${path.module}/../../../../../argocd/plugins/microservices/Dockerfile")
  }
}

# Usa il modulo ArgoCD
module "argocd" {
  source = "../../../../../terraform/modules/argocd" # Punta a terraform/modules/argocd

  # Variabili richieste dal modulo
  aws_region       = var.aws_region
  env              = var.env
  tags             = var.tags
  eks_cluster_name = "kind-argocd-test" # Mock EKS cluster name

  # Configurazione ArgoCD
  argocd_namespace     = var.argocd_namespace
  argocd_chart_version = var.argocd_chart_version
  argocd_custom_values = "${path.module}/local-overrides.yaml"
  deploy_argocd        = var.deploy_argocd

  # Credenziali repo (mock values)
  argocd_app_repo_username = var.argocd_app_repo_username
  argocd_app_repo_password = var.argocd_app_repo_password

  # Override credenziali admin per evitare AWS
  argocd_admin_bcrypt_password = bcrypt(random_password.argocd_admin.result)
  argocd_admin_password_mtime  = timestamp()

  # Override risorse per cluster kind locale
  controller_replicas = 1
  controller_resources = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
  }

  reposerver_replicas = 1
  reposerver_resources = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
  }

  server_replicas = 1
  server_resources = {
    limits = {
      cpu    = "500m"
      memory = "512Mi"
    }
    requests = {
      cpu    = "100m"
      memory = "256Mi"
    }
  }

  redis_resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "10m"
      memory = "64Mi"
    }
  }

  applicationset_replicas = 1
  applicationset_resources = {
    limits = {
      cpu    = "100m"
      memory = "128Mi"
    }
    requests = {
      cpu    = "50m"
      memory = "64Mi"
    }
  }

  # Note: Il modulo crea il namespace internamente
  # Le dipendenze sono gestite tramite AWS secret mocks creati prima
}
