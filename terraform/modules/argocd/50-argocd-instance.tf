# Get existing namespace if not deploying it
data "kubernetes_namespace_v1" "argocd" {
  count = var.deploy_argocd && var.deploy_argocd_namespace == true ? 0 : 1

  metadata {
    name = var.argocd_namespace
  }
}

# Crea ArgoCD namespace se richiesto
resource "kubernetes_namespace_v1" "argocd" {
  count = var.deploy_argocd && var.deploy_argocd_namespace == true ? 1 : 0

  metadata {
    name = var.argocd_namespace
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "helm_release" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  name       = "${var.project}-argocd"
  namespace  = local.argocd_namespace
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode(local.argocd_values)
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_bcrypt_password != "" ? var.argocd_admin_bcrypt_password : jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string).bcrypt_password
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = var.argocd_admin_password_mtime != "" ? var.argocd_admin_password_mtime : time_static.argocd_admin_credentials_update[0].rfc3339
  }

  set {
    name  = "crds.install"
    value = var.argocd_create_crds ? "true" : "false"
  }

  set {
    name  = "configs.cm.url"
    value = "https://${aws_route53_record.argocd_alb_alias[0].fqdn}"
  }

  # Explicit dependency on the merged file (when present)
  # This ensures that the provisioner runs before reading the file
  depends_on = [
    data.local_file.merged_values
  ]
}

resource "kubernetes_service_v1" "argogrpc" {
  metadata {
    name      = "argocd-server-grpc"
    namespace = var.argocd_namespace
    labels = {
      app = "argocd-server"
    }

    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol-version" = "GRPC"
    }
  }

  spec {
    type             = "ClusterIP"
    session_affinity = "None"

    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }

    port {
      name        = "grpc"
      port        = 80
      target_port = 8080
      protocol    = "TCP"
    }
  }
}
