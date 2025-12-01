# ArgoCD Terraform Module

Terraform module for deploying ArgoCD on Kubernetes clusters with support for custom plugins as sidecar containers. The module supports both AWS EKS deployments and local testing on kind.

## Features

- ✅ ArgoCD deployment via Helm chart with optimized configurations
- ✅ Support for custom plugins as sidecar containers (microservices, cronjobs)
- ✅ Admin credentials management via AWS Secrets Manager or local overrides
- ✅ Flexible resource configuration (CPU, memory, replicas) for all components
- ✅ Support for plugin images from public/private registries or local (kind)
- ✅ Custom health checks for Deployment, Pod, Application, ApplicationSet
- ✅ Performance optimizations (QPS, burst, timeouts, parallelism)
- ✅ AWS-optional mode for local testing without cloud credentials

## Module Structure

```
terraform/modules/argocd/
├── 00-main.tf                    # Provider requirements configuration
├── 01-locals.tf                  # Logic for building local values
├── 02-secrets.tf                 # Admin secret management (AWS or override)
├── 03-argocd-instance.tf         # ArgoCD deployment via Helm
├── 98-variables.tf               # Input variables
├── 99-outputs.tf                 # Module outputs
├── defaults/
│   └── argocd-cm-values.yaml    # Default values for Helm chart
└── argocd-local-testing/        # Setup for local testing with kind
    └── terraform-with-mocks/    # Usage example with AWS mocks
```

## Requirements

- **Terraform**: >= 1.8.0
- **Kubernetes Provider**: ~> 2.18.1
- **Helm Provider**: ~> 2.9.0
- **AWS Provider**: ~> 5.33.0 (optional if using overrides)

## Basic Usage (AWS EKS)

```hcl
module "argocd" {
  source = "./terraform/modules/argocd"

  # Basic configuration
  aws_region          = "eu-south-1"
  env                 = "production"
  eks_cluster_name    = "my-eks-cluster"
  argocd_namespace    = "argocd"
  argocd_chart_version = "9.1.0"

  # Repository credentials (optional)
  argocd_app_repo_username = "admin"
  argocd_app_repo_password = var.repo_password

  # Path to custom values (optional)
  argocd_custom_values = "path/to/custom-values.yaml"

  # Plugin configuration (with ECR registry)
  microservices_plugin_image_prefix = "123456789.dkr.ecr.eu-south-1.amazonaws.com"
  microservices_plugin_image_name   = "argocd-plugin-microservices"
  microservices_plugin_image_tag    = "v1.0.0"
  
  cronjobs_plugin_image_prefix = "123456789.dkr.ecr.eu-south-1.amazonaws.com"
  cronjobs_plugin_image_name   = "argocd-plugin-cronjobs"
  cronjobs_plugin_image_tag    = "v1.0.0"

  # Tags
  tags = {
    Environment = "production"
    Project     = "interop"
    ManagedBy   = "terraform"
  }
}
```

## Advanced Usage with Resource Override

```hcl
module "argocd" {
  source = "./terraform/modules/argocd"

  # ... basic configuration ...

  # Resource overrides for constrained clusters
  controller_resources = {
    requests = { cpu = "500m", memory = "1Gi" }
    limits   = { cpu = "2000m", memory = "4Gi" }
  }

  reposerver_resources = {
    requests = { cpu = "500m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "2Gi" }
  }

  server_resources = {
    requests = { cpu = "250m", memory = "512Mi" }
    limits   = { cpu = "1000m", memory = "2Gi" }
  }

  redis_resources = {
    requests = { cpu = "50m", memory = "128Mi" }
    limits   = { cpu = "200m", memory = "256Mi" }
  }

  applicationset_resources = {
    requests = { cpu = "50m", memory = "128Mi" }
    limits   = { cpu = "150m", memory = "256Mi" }
  }

  # Replica overrides
  controller_replicas   = 1
  reposerver_replicas  = 2
  server_replicas      = 2
  applicationset_replicas = 1
}
```

## Local Testing Usage (kind)

```hcl
module "argocd" {
  source = "./terraform/modules/argocd"

  # Minimal configuration
  aws_region       = "eu-south-1"  # Not used
  env              = "local"
  eks_cluster_name = "kind-cluster"  # Not used
  argocd_namespace = "argocd"
  argocd_chart_version = "9.1.0"
  argocd_custom_values = ""

  # AWS bypass with overrides
  argocd_admin_bcrypt_password = bcrypt("your-password-here")
  argocd_admin_password_mtime  = timestamp()

  # Local plugins (without registry prefix)
  microservices_plugin_image_prefix = ""
  microservices_plugin_image_name   = "argocd-plugin-microservices"
  microservices_plugin_image_tag    = "local"
  
  cronjobs_plugin_image_prefix = ""
  cronjobs_plugin_image_name   = "argocd-plugin-cronjobs"
  cronjobs_plugin_image_tag    = "local"

  # Reduced resources for kind
  controller_resources = {
    requests = { cpu = "100m", memory = "256Mi" }
    limits   = { cpu = "500m", memory = "512Mi" }
  }
  # ... other reduced resources ...
}
```

**Note:** For a complete local testing example, see the [`argocd-local-testing/terraform-with-mocks/`](./argocd-local-testing/terraform-with-mocks/) directory.

## Input Variables

### Required

| Name | Type | Description |
|------|------|-------------|
| `aws_region` | string | AWS region for cloud resources |
| `env` | string | Environment name (dev, staging, prod) |
| `eks_cluster_name` | string | EKS cluster name (used for AWS authentication) |
| `argocd_namespace` | string | Kubernetes namespace for ArgoCD |
| `argocd_chart_version` | string | ArgoCD Helm chart version (e.g. "9.1.0") |
| `argocd_custom_values` | string | Path to custom values file for Helm |
| `argocd_app_repo_username` | string | Username for application repository |
| `argocd_app_repo_password` | string | Password for application repository |

### Optional - AWS Bypass

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `argocd_admin_bcrypt_password` | string | null | Bcrypt hash of admin password (bypasses AWS Secrets Manager) |
| `argocd_admin_password_mtime` | string | null | RFC3339 timestamp for secret (bypasses AWS time_static) |

### Optional - Microservices Plugin

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `microservices_plugin_name` | string | "argocd-plugin-microservices" | Plugin container name |
| `microservices_plugin_image_prefix` | string | "" | Registry prefix (e.g. "ghcr.io/org") |
| `microservices_plugin_image_name` | string | "argocd-plugin-microservices" | Image name |
| `microservices_plugin_image_tag` | string | "local" | Image tag |

### Optional - Cronjobs Plugin

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `cronjobs_plugin_name` | string | "argocd-plugin-cronjobs" | Plugin container name |
| `cronjobs_plugin_image_prefix` | string | "" | Registry prefix (e.g. "ghcr.io/org") |
| `cronjobs_plugin_image_name` | string | "argocd-plugin-cronjobs" | Image name |
| `cronjobs_plugin_image_tag` | string | "local" | Image tag |

### Optional - Resource Override

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `controller_resources` | object | null | CPU/memory limits for controller |
| `reposerver_resources` | object | null | CPU/memory limits for repo-server |
| `server_resources` | object | null | CPU/memory limits for server |
| `redis_resources` | object | null | CPU/memory limits for redis |
| `applicationset_resources` | object | null | CPU/memory limits for applicationset |
| `controller_replicas` | number | null | Number of controller replicas |
| `reposerver_replicas` | number | null | Number of repo-server replicas |
| `server_replicas` | number | null | Number of server replicas |
| `applicationset_replicas` | number | null | Number of applicationset replicas |

### Other

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `deploy_argocd` | bool | true | Flag to enable/disable deployment |
| `tags` | map(any) | `{CreatedBy = "Terraform"}` | Tags to apply to AWS resources |

## Outputs

| Name | Description |
|------|-------------|
| `argocd_server_url` | Internal ArgoCD server URL (e.g. `https://argocd-server.argocd.svc.cluster.local`) |
| `argocd_admin_credentials` | Map with admin credentials (`username`, `password`, `bcryptPassword`, `passwordMtime`) |
| `argocd_namespace` | Namespace where ArgoCD is deployed |
| `argocd_admin_username` | Admin username (always "admin") |

## Default Configurations

The [`defaults/argocd-cm-values.yaml`](./defaults/argocd-cm-values.yaml) file contains optimized configurations for:

- **Performance**: QPS=100, Burst=200 for Kubernetes API
- **Timeouts**: Exec timeout 5m, reconciliation 120s, hard reconciliation 300s
- **Parallelism**: 50 status/operation processors, 30 repo parallelism, 100 kubectl parallelism
- **Plugin Sidecars**: extraContainers configuration for repo-server
- **Health Checks**: Custom health checks for Deployment, Pod, Application, ApplicationSet
- **Resource Exclusions**: Excludes Lease, Endpoints, Event from sync

### Default Resource Values

| Component | CPU Request | CPU Limit | Memory Request | Memory Limit | Replicas |
|-----------|-------------|-----------|----------------|--------------|----------|
| controller | 2 | 2 | 4Gi | 4Gi | 1 |
| repoServer | 1 | 1 | 4Gi | 4Gi | 2 |
| server | 1 | 1 | 3Gi | 3Gi | 2 |
| redis | 10m | 200m | 64Mi | 256Mi | 1 |
| applicationSet | 80m | 150m | 64Mi | 256Mi | 1 |

**Note:** These values can be overridden using the `*_resources` and `*_replicas` variables.

## Local Testing

The module includes a dedicated directory for local testing without AWS dependencies:

```
argocd-local-testing/
├── terraform-with-mocks/     # Terraform configuration for kind
│   ├── main.tf              # Module call with overrides
│   ├── variables.tf         # Variables for testing
│   ├── outputs.tf           # Outputs
│   └── README.md            # Complete testing guide
└── scripts/
    └── setup-kind-only.sh   # Script to create kind cluster
```

### Quick Start for Testing

```bash
# 1. Create kind cluster
cd terraform/modules/argocd/argocd-local-testing
./scripts/setup-kind-only.sh

# 2. Run Terraform
cd terraform-with-mocks
terraform init
terraform apply

# 3. Access UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Username: admin
# Password: terraform output -raw argocd_admin_password
```

For the complete testing guide, see [argocd-local-testing/terraform-with-mocks/README.md](./argocd-local-testing/terraform-with-mocks/README.md).

## Module Architecture

### 1. AWS-Optional Pattern

The module supports deployment with or without AWS Secrets Manager:

- **With AWS**: Admin credentials are generated and stored in AWS Secrets Manager
- **Without AWS**: Credentials are passed via override variables (`argocd_admin_bcrypt_password`, `argocd_admin_password_mtime`)

AWS resources are conditionally created:
```hcl
count = var.deploy_argocd && var.argocd_admin_bcrypt_password == null ? 1 : 0
```

### 2. Plugin Image Construction

The module builds plugin image paths flexibly:

- **With registry**: `<prefix>/<name>:<tag>` → `ghcr.io/org/plugin:v1.0.0`
- **Without registry** (kind): `<name>:<tag>` → `plugin:local`

This allows using the same module for production and local testing.

### 3. Resource Override via Dynamic Set Blocks

Resource overrides are implemented using dynamic `set` blocks in Helm:

```hcl
dynamic "set" {
  for_each = var.controller_resources != null ? [1] : []
  content {
    name  = "controller.resources.requests.cpu"
    value = var.controller_resources.requests.cpu
  }
}
```

This approach allows granular overrides without losing complex configurations like `extraContainers`.

### 4. Plugin Sidecar Injection

ArgoCD plugins are configured as sidecar containers in the repo-server:

```yaml
repoServer:
  extraContainers:
    - name: argocd-plugin-microservices
      image: ${microservices_plugin_image}
      command: [/var/run/argocd/argocd-cmp-server]
      # ... volumeMounts, env ...
```

This pattern allows extending ArgoCD with custom logic for manifest rendering.

## Troubleshooting

### Error: context deadline exceeded

**Cause**: Timeout during Helm installation.

**Solution**: Increase timeout in `03-argocd-instance.tf` or allocate more resources to the cluster.

### Missing plugin container

**Cause**: Plugin images not available or incorrect image path.

**Solution**: 
- Verify images exist in the specified registry
- For kind, ensure images are loaded: `kind load docker-image <image> --name <cluster>`

### Pod in OOMKilled

**Cause**: Insufficient memory limits.

**Solution**: Increase values in `*_resources.limits.memory` or reduce defaults in `argocd-cm-values.yaml`.
