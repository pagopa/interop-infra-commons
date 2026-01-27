variable "aws_region" {
  type        = string
  description = "AWS region"
}
variable "project" {
  type        = string
  description = "Project name used for resource naming"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of the EKS cluster accessing the ArgoCD cluster"
}

variable "argocd_custom_values" {
  type        = string
  description = "Path to a custom values file to override default ArgoCD configuration values."
  default     = null
}

variable "argocd_chart_version" {
  type        = string
  description = "Version of the ArgoCD Helm chart to deploy."
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace where ArgoCD will be deployed."
}

variable "argocd_app_repo_username" {
  type        = string
  description = "Username for the ArgoCD application repository."
}

variable "argocd_app_repo_password" {
  type        = string
  description = "Password for the ArgoCD application repository."
}

variable "argocd_create_crds" {
  type        = bool
  description = "Flag to determine whether to create ArgoCD CRDs."
  default     = true
}

variable "deploy_argocd" {
  type        = bool
  description = "Flag to determine whether to deploy ArgoCD."
  default     = true
}

variable "deploy_argocd_namespace" {
  type        = bool
  description = "Flag to determine whether to deploy the ArgoCD namespace."
  default     = true
}
variable "secret_prefix" {
  description = "Prefix for the secret that will be created"
  type        = string
  default     = "k8s/argocd/"
}

variable "secret_tags" {
  description = "Tags to apply to the secret that will be created"
  type        = map(string)
  default     = {}
}

variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 0
}

variable "argocd_admin_bcrypt_password" {
  type        = string
  description = "Optional override: bcrypt hash of ArgoCD admin password. If provided, AWS Secrets Manager resources are skipped. Use empty string to auto-generate from AWS Secrets Manager."
  default     = ""
}

variable "argocd_admin_password_mtime" {
  type        = string
  description = "Optional override: mtime string for ArgoCD admin password secret (e.g., RFC3339). If provided, AWS time_static is skipped. Use empty string to skip AWS time_static."
  default     = ""
}

variable "aws_lb_controller_role_name" {
  type        = string
  description = "Name of the IAM role to be assumed by the AWS Load Balancer Controller service account"
}

variable "aws_lb_controller_chart_version" {
  type        = string
  description = "Chart version for AWS Load Balancer Controller"
}

variable "aws_lb_controller_replicas" {
  type        = number
  description = "Replica count for AWS Load Balancer Controller"
}

#variable "vpn_clients_security_group_id" {
#  type        = string
#  description = "ID of the VPN clients SG"
#}
#
#variable "private_subnet_ids" {
#  type        = list(string)
#  description = "List of private subnet IDs for ALB placement"
#}
#
## ALB exposure variables
#variable "enable_argocd_alb" {
#  type        = bool
#  description = "Enable creation of ALB to expose ArgoCD"
#  default     = true
#}
#
#variable "argocd_domain" {
#  type        = string
#  description = "Domain name for ArgoCD (e.g. argocd.internal.example.com)"
#  default     = null
#}
#
#variable "acm_cert_arn" {
#  type        = string
#  description = "ACM certificate ARN for ALB HTTPS listener"
#  default     = null
#}
#
#variable "alb_internal" {
#  type        = bool
#  description = "Whether the ALB is internal (true) or internet-facing (false)"
#  default     = true
#}
#
#variable "alb_security_group_id" {
#  type        = string
#  description = "Optional Security Group ID to attach to the ALB. If null, a new SG limited to VPN clients will be created."
#  default     = null
#}
#
#variable "create_private_hosted_zone" {
#  type        = bool
#  description = "If true, create a Private Hosted Zone for the provided domain and associate it with VPC"
#  default     = false
#}
#
#variable "route53_zone_id" {
#  type        = string
#  description = "Optional existing Route53 Hosted Zone ID. If null and create_private_hosted_zone=false, no DNS record is created."
#  default     = null
#}

# Testing mode - disables AWS data sources
variable "local_testing_mode" {
  type        = bool
  description = "Enable local testing mode (disables AWS data sources for local kind clusters)"
  default     = false
}
