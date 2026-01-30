# ArgoCD Terraform Module

Terraform module for deploying ArgoCD on Kubernetes clusters (AWS EKS or local kind). The module supports optional AWS networking resources (Route53, ACM, ALB) for exposing ArgoCD via an internal HTTPS load balancer and includes a local testing mode.

## Features

- ArgoCD deployment via Helm chart
- Optional creation of ArgoCD namespace
- Admin credentials managed by AWS Secrets Manager or provided via overrides
- Optional internal ALB with HTTPS, ACM certificate, and Route53 private hosted zone
- Separate target groups for UI (HTTP1) and gRPC (HTTP2)
- TargetGroupBinding resources for AWS Load Balancer Controller
- Optional merge of custom Helm values using `yq`
- Local testing mode using kubeconfig (kind)

## Module Structure

```
terraform/modules/argocd/
├── 00-main.tf                    # Providers and configuration
├── 10-data.tf                    # Data sources and values merge
├── 20-locals.tf                  # Local values and validations
├── 30-secrets.tf                 # Admin secret management
├── 40-route53.tf                 # Route53 and ACM resources
├── 43-alb.tf                     # ALB and Route53 alias record
├── 44-alb-target-groups.tf       # Target groups, listeners, and TargetGroupBinding
├── 50-argocd-instance.tf         # ArgoCD Helm release and gRPC service
├── 98-variables.tf               # Input variables
├── 99-outputs.tf                 # Module outputs
├── scripts/
│   └── merge-values.sh           # Deep-merge YAML values via yq
├── values/
│   └── argocd-cm-values.yaml      # Default Helm values
└── README.md                     # This file

# Local testing (see test/terraform/modules/argocd/)
test/terraform/modules/argocd/
├── scripts/
│   ├── setup-kind-only.sh
│   └── teardown-kind-cluster.sh
└── terraform-with-mocks/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── local-overrides.yaml
    └── README.md
```

## Requirements

- **Terraform**: ~> 1.8.0
- **AWS Provider**: ~> 5.46.0
- **Kubernetes Provider**: ~> 2.30.0
- **Helm Provider**: ~> 2.13.2
- **ArgoCD Provider**: 7.11.2
- **kubectl Provider**: ~> 1.14.0
- **yq**: required only when using `argocd_custom_values`

## Usage

### AWS EKS with ALB + Route53

```hcl
module "argocd" {
  source = "./terraform/modules/argocd"

  # Core configuration
  aws_region          = "eu-south-1"
  project             = "interop"
  env                 = "production"
  eks_cluster_name    = "my-eks-cluster"
  argocd_namespace    = "argocd"
  argocd_chart_version = "9.1.0"

  # Repository credentials (optional)
  argocd_app_repo_username = "admin"
  argocd_app_repo_password = var.repo_password

  # Optional custom values
  argocd_custom_values = "path/to/custom-values.yaml"

  # ALB + Route53 + ACM
  create_argocd_alb        = true
  create_private_hosted_zone = true
  public_hosted_zone_name  = "dev.interop.pagopa.it"
  argocd_subdomain          = "argocd"
  vpn_clients_security_group_id = "sg-0123456789abcdef0"
  private_subnet_ids        = ["subnet-aaa", "subnet-bbb", "subnet-ccc"]

  tags = {
    Environment = "production"
    Project     = "interop"
    ManagedBy   = "terraform"
  }
}
```

### Local Testing (kind)

```hcl
module "argocd" {
  source = "./terraform/modules/argocd"

  aws_region          = "eu-south-1"
  project             = "interop"
  env                 = "local"
  eks_cluster_name    = "kind-argocd-test"
  argocd_namespace    = "argocd"
  argocd_chart_version = "6.10.0"

  argocd_app_repo_username = "admin"
  argocd_app_repo_password = "password"

  # Disable ALB/Route53 (automatically enables local testing mode)
  create_argocd_alb         = false
  create_private_hosted_zone = false

  # Optional override to avoid AWS Secrets Manager
  argocd_admin_bcrypt_password = bcrypt("your-password-here")
  argocd_admin_password_mtime  = timestamp()
}
```

**Note:** When `create_argocd_alb = false`, the module automatically infers local testing mode and uses kubeconfig instead of EKS credentials.

**Note:** For a complete local testing example (including AWS mocks), see the [`test/terraform/modules/argocd/terraform-with-mocks/`](../../../test/terraform/modules/argocd/terraform-with-mocks/) directory.

## Networking (Route53 + ACM + ALB)

When `create_argocd_alb` and `create_private_hosted_zone` are enabled, the module:

- Creates a private Route53 hosted zone for the provided `public_hosted_zone_name`
- Requests an ACM certificate validated through the public hosted zone
- Creates an internal ALB with HTTPS listener
- Adds two target groups (UI HTTP1 and gRPC HTTP2)
- Creates a Route53 alias record for `${argocd_subdomain}.${public_hosted_zone_name}`
- Binds target groups to Kubernetes services via TargetGroupBinding resources

The AWS Load Balancer Controller and its CRDs must be installed in the cluster to use `kubernetes_manifest` TargetGroupBinding resources.

## Input Variables

### Core

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `aws_region` | string | n/a | AWS region |
| `project` | string | n/a | Project name used for resource naming |
| `env` | string | n/a | Environment name |
| `eks_cluster_name` | string | n/a | EKS cluster name |
| `argocd_namespace` | string | n/a | Kubernetes namespace for ArgoCD |
| `argocd_chart_version` | string | n/a | ArgoCD Helm chart version |
| `argocd_app_repo_username` | string | n/a | Reserved for future use (not consumed by the module yet) |
| `argocd_app_repo_password` | string | n/a | Reserved for future use (not consumed by the module yet) |

### ArgoCD / Helm

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `argocd_custom_values` | string | null | Path to custom values YAML (merged with defaults) |
| `argocd_create_crds` | bool | true | Install ArgoCD CRDs |
| `deploy_argocd` | bool | true | Enable/disable ArgoCD deployment |
| `deploy_argocd_namespace` | bool | true | Create namespace if true |
| `argocd_helm_timeout_seconds` | number | 600 | Helm operation timeout |

### Secrets Management

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `secret_prefix` | string | "k8s/argocd/" | Secrets Manager prefix |
| `secret_tags` | map(string) | {} | Tags for Secrets Manager secret |
| `secret_recovery_window_in_days` | number | 0 | Recovery window for secret deletion |
| `argocd_admin_bcrypt_password` | string | "" | Override admin bcrypt password (skip Secrets Manager) |
| `argocd_admin_password_mtime` | string | "" | Override admin password mtime |

### Route53 / ACM / ALB

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `create_private_hosted_zone` | bool | false | Create private hosted zone and associate to VPC |
| `create_argocd_alb` | bool | true | Create internal ALB for ArgoCD |
| `public_hosted_zone_name` | string | null | Public hosted zone name for ACM DNS validation |
| `argocd_subdomain` | string | null | Subdomain used for ArgoCD DNS record |
| `argocd_alb_name` | string | null | Reserved for future use (not consumed by the module yet) |
| `vpn_clients_security_group_id` | string | n/a | VPN clients security group ID (used by ALB SG) |
| `private_subnet_ids` | list(string) | n/a | Private subnets for ALB |

### Tags

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `tags` | map(any) | `{CreatedBy = "Terraform"}` | Tags applied to AWS resources |

**Note:** Local testing mode is automatically inferred when `create_argocd_alb = false`. The module will use kubeconfig instead of EKS credentials.

## Outputs

| Name | Description |
|------|-------------|
| `argocd_server_url` | Internal ArgoCD server URL |
| `argocd_admin_credentials` | Admin credentials secret data (sensitive) |
| `argocd_alb_dns_name` | DNS name of the ArgoCD ALB |
| `argocd_alb_arn` | ARN of the ArgoCD ALB |
| `argocd_route53_record_fqdn` | FQDN of the Route53 alias record |
| `argocd_alb_url` | Full HTTPS URL to access ArgoCD via ALB |

## Troubleshooting

### Error: yq is not installed

**Cause**: `argocd_custom_values` is set and the merge script requires `yq`.

**Solution**: Install `yq` on the machine running Terraform.

### Error: TargetGroupBinding CRD not found

**Cause**: AWS Load Balancer Controller is not installed in the cluster.

**Solution**: Install the AWS Load Balancer Controller and its CRDs before applying.

### Error: Missing public hosted zone

**Cause**: `public_hosted_zone_name` does not exist or is not accessible.

**Solution**: Ensure the public hosted zone exists in Route53 and matches the provided name.

### Error: context deadline exceeded

**Cause**: Timeout during Helm installation.

**Solution**: Increase `argocd_helm_timeout_seconds` or allocate more resources to the cluster.
