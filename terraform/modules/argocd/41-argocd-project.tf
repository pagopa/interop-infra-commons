# ArgoCD AppProject per abilitare deployment e lookup sul cluster
resource "kubectl_manifest" "argocd_project" {
  count = var.deploy_argocd && var.create_argocd_project ? 1 : 0

  yaml_body = yamlencode({
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = var.argocd_project_name
      namespace = local.argocd_namespace
      finalizers = [
        "resources-finalizer.argocd.argoproj.io"
      ]
    }
    spec = {
      description = var.argocd_project_description

      # Repositories allowed for this project
      sourceRepos = var.argocd_project_source_repos

      sourceNamespaces = var.argocd_project_source_namespaces

      # Destination clusters and namespaces
      destinations = [
        for dest in var.argocd_project_destinations : {
          server    = dest.server
          namespace = dest.namespace
        }
      ]

      # Cluster resource whitelist
      clusterResourceWhitelist = var.argocd_project_cluster_resource_whitelist

      # Namespace resource whitelist
      namespaceResourceWhitelist = var.argocd_project_namespace_resource_whitelist

      # Orphaned resources monitoring
      orphanedResources = {
        warn = var.argocd_project_orphaned_resources_warn
      }

      # Roles for the project
      roles = [
        for role in var.argocd_project_roles : {
          name        = role.name
          description = role.description
          policies    = role.policies
          groups      = try(role.groups, [])
        }
      ]
    }
  })

  depends_on = [helm_release.argocd]
}
