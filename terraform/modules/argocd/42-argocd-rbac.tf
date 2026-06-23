# ClusterRole per ArgoCD - permessi di lettura e gestione risorse cluster-wide
resource "kubernetes_cluster_role_v1" "argocd_application_controller" {
  count = var.deploy_argocd && var.create_argocd_rbac ? 1 : 0

  metadata {
    name = "${var.resource_prefix}-argocd-application-controller-${var.env}"
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
    name = "${var.resource_prefix}-argocd-application-controller-${var.env}"
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
    name = "${var.resource_prefix}-argocd-server-${var.env}"
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
    name = "${var.resource_prefix}-argocd-server-${var.env}"
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
    name = "${var.resource_prefix}-argocd-repo-server-${var.env}"
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
    name = "${var.resource_prefix}-argocd-repo-server-${var.env}"
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
    name      = "${var.resource_prefix}-argocd-repo-server"
    namespace = local.argocd_namespace
  }
}

# ApplicationSet Role to access specific namespaces
resource "kubernetes_role_v1" "applicationset_ns_dev_experimental_argocd" {
  metadata {
    name      = "${var.resource_prefix}-argocd-applicationset-controller-${var.env}"
    namespace = local.argocd_namespace
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["applications", "applicationsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # AppProjects (solo lettura)
  rule {
    api_groups = ["argoproj.io"]
    resources  = ["appprojects"]
    verbs      = ["get", "list", "watch"]
  }

  # ConfigMaps + Secrets (necessari per lookup/generator)
  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "applicationset_ns_dev_experimental_argocd" {
  metadata {
    name      = "${var.resource_prefix}-argocd-applicationset-controller-${var.env}"
    namespace = local.argocd_namespace
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.applicationset_ns_dev_experimental_argocd.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-applicationset-controller"
    namespace = local.argocd_namespace
  }
}
resource "kubernetes_role_v1" "applicationset_ns_dev_experimental_argocd_interop_apps" {
  metadata {
    name      = "${var.resource_prefix}-argocd-applicationset-controller-${var.env}"
    namespace = "dev-experimental-argocd-interop-apps"
  }

  rule {
    api_groups = ["argoproj.io"]
    resources  = ["applications", "applicationsets"]
    verbs      = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # AppProjects (solo lettura)
  rule {
    api_groups = ["argoproj.io"]
    resources  = ["appprojects"]
    verbs      = ["get", "list", "watch"]
  }

  # ConfigMaps + Secrets (necessari per lookup/generator)
  rule {
    api_groups = [""]
    resources  = ["configmaps", "secrets"]
    verbs      = ["get", "list", "watch"]
  }
}

resource "kubernetes_role_binding_v1" "applicationset_ns_dev_experimental_argocd_interop_apps" {
  metadata {
    name      = "${var.resource_prefix}-argocd-applicationset-controller-${var.env}"
    namespace = "dev-experimental-argocd-interop-apps"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role_v1.applicationset_ns_dev_experimental_argocd_interop_apps.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-applicationset-controller"
    namespace = local.argocd_namespace
  }
}

# ClusterRole per ApplicationSet Controller - permessi cluster-wide per supportare generatori e gestione risorse cluster-wide
# Mapping from https://github.com/argoproj/argo-helm/blob/main/charts/argo-cd/templates/argocd-applicationset/clusterrole.yaml
resource "kubernetes_cluster_role_v1" "argocd_applicationset_cluster_permissions" {
  metadata {
    name = "argocd-applicationset-controller-cluster-permissions"
  }

  # argoproj.io resources
  rule {
    api_groups = ["argoproj.io"]
    resources = [
      "applications",
      "applications/finalizers",
      "applicationsets",
      "applicationsets/finalizers",
      "applicationsets/status",
      "appprojects"
    ]
    verbs = ["get", "list", "watch", "create", "update", "patch", "delete"]
  }

  # Secrets
  rule {
    api_groups = [""]
    resources  = ["secrets", "configmaps"]
    verbs      = ["get", "list", "watch"]
  }

  # Events
  rule {
    api_groups = [""]
    resources  = ["events"]
    verbs      = ["create", "patch"]
  }

  # Cluster generator support
  rule {
    api_groups = ["argoproj.io"]
    resources = ["clusters"]
    verbs = ["get", "list", "watch"]
  }

  # Repository generator support
  rule {
    api_groups = ["argoproj.io"]
    resources = ["repositories"]
    verbs = ["get", "list", "watch"]
  }

}

resource "kubernetes_cluster_role_binding_v1" "argocd_applicationset_cluster_permissions" {
  metadata {
    name = "argocd-applicationset-controller-cluster-permissions"
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "ClusterRole"
    name      = kubernetes_cluster_role_v1.argocd_applicationset_cluster_permissions.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = "argocd-applicationset-controller"
    namespace = local.argocd_namespace
  }
}
