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

variable "argocd_helm_timeout_seconds" {
  type        = number
  description = "Timeout in seconds for Helm operations when deploying ArgoCD."
  default     = 600
}

#########################################################
# ArgoCD Route53 / ACM / ALB / ALB Controller variables #
#########################################################

variable "create_private_hosted_zone" {
  type        = bool
  description = "If true, create a Private Hosted Zone for the provided domain and associate it with VPC"
  default     = false
}

variable "create_argocd_alb" {
  type        = bool
  description = "Enable creation of ALB to expose ArgoCD"
  default     = true
}

variable "public_hosted_zone_name" {
  type        = string
  description = "The name of the public hosted zone (e.g., dev.interop.pagopa.it) used to resolve ACM DNS validation records."
  default     = null
}

variable "argocd_subdomain" {
  type        = string
  description = "Sub-Domain name for ArgoCD (e.g. argocd) that will be used to create the full domain name (e.g. argocd.dev.interop.pagopa.it) when creating Route53 records."
  default     = null
}

variable "argocd_alb_name" {
  type        = string
  description = "Name of the ALB to be created for ArgoCD"
  default     = null
}


variable "vpn_clients_security_group_id" {
  type        = string
  description = "ID of the VPN clients SG"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ALB placement"
}

# Testing mode - disables AWS data sources
variable "local_testing_mode" {
  type        = bool
  description = "Enable local testing mode (disables AWS data sources for local kind clusters)"
  default     = false
}
