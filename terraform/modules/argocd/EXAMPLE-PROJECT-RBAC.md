# Example: ArgoCD with Project and Cluster RBAC

This example demonstrates how to use the ArgoCD module with:
- ArgoCD AppProject creation
- ClusterRole and ClusterRoleBinding for cluster-wide resource lookup

## Prerequisites

- AWS EKS cluster
- kubectl configured
- Terraform ~> 1.8.0

## Configuration

```hcl
module "argocd" {
  source = "../../modules/argocd"

  # Core configuration
  aws_region       = "eu-south-1"
  resource_prefix  = "dev-interop"
  env              = "dev"
  eks_cluster_name = "dev-interop-eks"
  argocd_namespace = "argocd"
  argocd_chart_version = "9.1.0"

  # Repository credentials
  argocd_app_repo_username = "admin"
  argocd_app_repo_password = var.argocd_repo_password

  # ALB Configuration (optional)
  create_argocd_alb           = true
  create_private_hosted_zone  = true
  public_hosted_zone_name     = "dev.interop.pagopa.it"
  argocd_subdomain            = "argocd"
  vpn_clients_security_group_id = var.vpn_sg_id
  private_subnet_ids          = var.private_subnet_ids

  # ArgoCD Project Configuration
  create_argocd_project      = true
  argocd_project_name        = "interop-applications"
  argocd_project_description = "Project for Interop platform applications"
  
  # Allow specific Git repositories
  argocd_project_source_repos = [
    "https://github.com/pagopa/interop-*",
    "https://github.com/myorg/helm-charts"
  ]
  
  # Define allowed destinations (clusters and namespaces)
  argocd_project_destinations = [
    {
      server    = "https://kubernetes.default.svc"  # In-cluster
      namespace = "interop-*"                        # Wildcard for all interop namespaces
    },
    {
      server    = "https://kubernetes.default.svc"
      namespace = "monitoring"
    }
  ]
  
  # Restrict cluster resources (optional - default allows all)
  argocd_project_cluster_resource_whitelist = [
    {
      group = ""
      kind  = "Namespace"
    },
    {
      group = "rbac.authorization.k8s.io"
      kind  = "*"
    }
  ]
  
  # Restrict namespace resources (optional - default allows all)
  argocd_project_namespace_resource_whitelist = [
    {
      group = "*"
      kind  = "*"
    }
  ]
  
  # Enable orphaned resources warnings
  argocd_project_orphaned_resources_warn = true
  
  # Define project roles (optional)
  argocd_project_roles = [
    {
      name        = "ci-deployer"
      description = "Role for CI/CD pipeline deployments"
      policies = [
        "p, proj:interop-applications:ci-deployer, applications, *, interop-applications/*, allow"
      ]
      groups = []
    },
    {
      name        = "read-only"
      description = "Read-only access to project applications"
      policies = [
        "p, proj:interop-applications:read-only, applications, get, interop-applications/*, allow"
      ]
      groups = ["developers"]
    }
  ]

  # Enable RBAC for cluster-wide resource lookup
  create_argocd_rbac = true
  
  # Use default ServiceAccount names (optional override)
  argocd_application_controller_sa_name = "argocd-application-controller"
  argocd_server_sa_name                 = "argocd-server"
  argocd_repo_server_sa_name            = "argocd-repo-server"

  tags = {
    Environment = "dev"
    Project     = "interop"
    ManagedBy   = "terraform"
  }
}
```

## What Gets Created

### 1. ArgoCD AppProject
- **Resource**: `AppProject` custom resource
- **Purpose**: Defines allowed source repositories, destination clusters/namespaces, and resource types
- **Namespace**: Same as ArgoCD installation

### 2. ClusterRole Resources
The module creates three ClusterRoles:

#### a. Application Controller ClusterRole
- **Name**: `{resource_prefix}-argocd-application-controller`
- **Permissions**: Full CRUD on most resources for deployment and sync operations
- **Bound to**: `argocd-application-controller` ServiceAccount

#### b. Server ClusterRole
- **Name**: `{resource_prefix}-argocd-server`
- **Permissions**: Read-only access for UI and CLI operations
- **Bound to**: `argocd-server` ServiceAccount

#### c. Repo Server ClusterRole
- **Name**: `{resource_prefix}-argocd-repo-server`
- **Permissions**: Read access to ConfigMaps, Secrets, Services, and Namespaces
- **Bound to**: `argocd-repo-server` ServiceAccount

### 3. ClusterRoleBindings
Each ClusterRole gets a corresponding ClusterRoleBinding that binds it to the appropriate ArgoCD ServiceAccount.

## Verification

After applying, verify the resources:

```bash
# Check ArgoCD Project
kubectl get appproject -n argocd

# Check ClusterRoles
kubectl get clusterrole | grep argocd

# Check ClusterRoleBindings
kubectl get clusterrolebinding | grep argocd

# Verify ServiceAccounts
kubectl get sa -n argocd
```

## Accessing ArgoCD

```bash
# Get the ArgoCD URL (if ALB is enabled)
terraform output argocd_alb_url

# Get admin credentials
terraform output -json argocd_admin_credentials
```

## Security Considerations

1. **Principle of Least Privilege**: Customize `cluster_resource_whitelist` and `namespace_resource_whitelist` to restrict what can be deployed
2. **Source Repositories**: Use specific repository patterns instead of wildcards
3. **Destinations**: Limit namespaces and clusters where applications can be deployed
4. **RBAC**: The created ClusterRoles provide broad permissions - consider further restrictions based on your security requirements

## Cleanup

```bash
terraform destroy
```

**Note**: ArgoCD Applications managed by the project should be deleted first to avoid orphaned resources.
