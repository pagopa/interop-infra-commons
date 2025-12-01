# Crea namespace ArgoCD
resource "kubernetes_namespace_v1" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  metadata {
    name = var.argocd_namespace
  }
}

resource "helm_release" "argocd" {
  count = var.deploy_argocd ? 1 : 0

  name       = "argocd"
  namespace  = kubernetes_namespace_v1.argocd[0].metadata[0].name
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = var.argocd_chart_version

  values = [
    yamlencode(local.argocd_values)
  ]

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_bcrypt_password != null ? var.argocd_admin_bcrypt_password : jsondecode(aws_secretsmanager_secret_version.argocd_admin_credentials[0].secret_string).bcrypt_password
  }

  set {
    name  = "configs.secret.argocdServerAdminPasswordMtime"
    value = var.argocd_admin_password_mtime != null ? var.argocd_admin_password_mtime : time_static.argocd_admin_credentials_update[0].rfc3339
  }

  set {
    name  = "crds.install"
    value = "true"
  }

  # Override replicas per ambiente locale
  dynamic "set" {
    for_each = var.controller_replicas != null ? [1] : []
    content {
      name  = "controller.replicas"
      value = var.controller_replicas
    }
  }

  dynamic "set" {
    for_each = var.reposerver_replicas != null ? [1] : []
    content {
      name  = "repoServer.replicas"
      value = var.reposerver_replicas
    }
  }

  dynamic "set" {
    for_each = var.server_replicas != null ? [1] : []
    content {
      name  = "server.replicas"
      value = var.server_replicas
    }
  }

  dynamic "set" {
    for_each = var.applicationset_replicas != null ? [1] : []
    content {
      name  = "applicationSet.replicas"
      value = var.applicationset_replicas
    }
  }

  # Override resources
  dynamic "set" {
    for_each = var.controller_resources != null ? [1] : []
    content {
      name  = "controller.resources.limits.cpu"
      value = var.controller_resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.controller_resources != null ? [1] : []
    content {
      name  = "controller.resources.limits.memory"
      value = var.controller_resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.controller_resources != null ? [1] : []
    content {
      name  = "controller.resources.requests.cpu"
      value = var.controller_resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.controller_resources != null ? [1] : []
    content {
      name  = "controller.resources.requests.memory"
      value = var.controller_resources.requests.memory
    }
  }

  dynamic "set" {
    for_each = var.reposerver_resources != null ? [1] : []
    content {
      name  = "repoServer.resources.limits.cpu"
      value = var.reposerver_resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.reposerver_resources != null ? [1] : []
    content {
      name  = "repoServer.resources.limits.memory"
      value = var.reposerver_resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.reposerver_resources != null ? [1] : []
    content {
      name  = "repoServer.resources.requests.cpu"
      value = var.reposerver_resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.reposerver_resources != null ? [1] : []
    content {
      name  = "repoServer.resources.requests.memory"
      value = var.reposerver_resources.requests.memory
    }
  }

  dynamic "set" {
    for_each = var.server_resources != null ? [1] : []
    content {
      name  = "server.resources.limits.cpu"
      value = var.server_resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.server_resources != null ? [1] : []
    content {
      name  = "server.resources.limits.memory"
      value = var.server_resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.server_resources != null ? [1] : []
    content {
      name  = "server.resources.requests.cpu"
      value = var.server_resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.server_resources != null ? [1] : []
    content {
      name  = "server.resources.requests.memory"
      value = var.server_resources.requests.memory
    }
  }

  dynamic "set" {
    for_each = var.redis_resources != null ? [1] : []
    content {
      name  = "redis.resources.limits.cpu"
      value = var.redis_resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.redis_resources != null ? [1] : []
    content {
      name  = "redis.resources.limits.memory"
      value = var.redis_resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.redis_resources != null ? [1] : []
    content {
      name  = "redis.resources.requests.cpu"
      value = var.redis_resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.redis_resources != null ? [1] : []
    content {
      name  = "redis.resources.requests.memory"
      value = var.redis_resources.requests.memory
    }
  }

  dynamic "set" {
    for_each = var.applicationset_resources != null ? [1] : []
    content {
      name  = "applicationSet.resources.limits.cpu"
      value = var.applicationset_resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.applicationset_resources != null ? [1] : []
    content {
      name  = "applicationSet.resources.limits.memory"
      value = var.applicationset_resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.applicationset_resources != null ? [1] : []
    content {
      name  = "applicationSet.resources.requests.cpu"
      value = var.applicationset_resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.applicationset_resources != null ? [1] : []
    content {
      name  = "applicationSet.resources.requests.memory"
      value = var.applicationset_resources.requests.memory
    }
  }
}