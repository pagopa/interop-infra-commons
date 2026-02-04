# ClusterRole per ArgoCD - permessi di lettura e gestione risorse cluster-wide
resource "kubernetes_cluster_role_v1" "argocd_application_controller" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-application-controller"
    labels = {
      "app.kubernetes.io/name"       = "argocd-application-controller"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Permessi per la lookup e gestione delle risorse
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list", "watch"]
  }

  rule {
    api_groups = [""]
    resources = [
      "events",
      "configmaps",
      "secrets",
      "serviceaccounts",
      "services",
      "pods",
      "pods/log"
    ]
    verbs = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["apps"]
    resources = [
      "deployments",
      "daemonsets",
      "replicasets",
      "statefulsets"
    ]
    verbs = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["batch"]
    resources = [
      "jobs",
      "cronjobs"
    ]
    verbs = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }

  rule {
    api_groups = ["argoproj.io"]
    resources = [
      "rollouts",
      "rollouts/status",
      "rollouts/finalizers"
    ]
    verbs = ["create", "get", "list", "watch", "update", "patch", "delete"]
  }
}

# ClusterRoleBinding per Application Controller
resource "kubernetes_cluster_role_binding_v1" "argocd_application_controller" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-application-controller"
    labels = {
      "app.kubernetes.io/name"       = "argocd-application-controller"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_application_controller[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.argocd_application_controller_sa_name
    namespace = local.argocd_namespace
  }
}

# ClusterRole per ArgoCD Server - permessi di lettura
resource "kubernetes_cluster_role_v1" "argocd_server" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-server"
    labels = {
      "app.kubernetes.io/name"       = "argocd-server"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  # Permessi di lettura per la UI e CLI
  rule {
    api_groups = ["*"]
    resources  = ["*"]
    verbs      = ["get", "list"]
  }

  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["list"]
  }

  rule {
    api_groups = [""]
    resources  = ["pods", "pods/log"]
    verbs      = ["get", "list"]
  }
}

# ClusterRoleBinding per ArgoCD Server
resource "kubernetes_cluster_role_binding_v1" "argocd_server" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-server"
    labels = {
      "app.kubernetes.io/name"       = "argocd-server"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_server[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.argocd_server_sa_name
    namespace = local.argocd_namespace
  }
}

# ClusterRole per ArgoCD Repo Server - permessi di lettura ConfigMap e Secrets
resource "kubernetes_cluster_role_v1" "argocd_repo_server" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-repo-server"
    labels = {
      "app.kubernetes.io/name"       = "argocd-repo-server"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  rule {
    api_groups = [""]
    resources = [
      "configmaps",
      "secrets",
      "services",
      "namespaces"
    ]
    verbs = ["get", "list", "watch"]
  }
}

# ClusterRoleBinding per Repo Server
resource "kubernetes_cluster_role_binding_v1" "argocd_repo_server" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-repo-server"
    labels = {
      "app.kubernetes.io/name"       = "argocd-repo-server"
      "app.kubernetes.io/part-of"    = "argocd"
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_repo_server[0].metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = var.argocd_repo_server_sa_name
    namespace = local.argocd_namespace
  }
}
