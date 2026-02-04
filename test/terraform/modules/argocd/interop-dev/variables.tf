variable "aws_region" {
  type        = string
  description = "AWS region"
  default     = "eu-south-1"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "dev-experimental-argocd"
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace where ArgoCD will be deployed."
  default     = "dev-experimental-argocd"
}

variable "argocd_chart_version" {
  type        = string
  description = "Version of the ArgoCD Helm chart to deploy."
  default     = "9.1.0"
}

variable "argocd_custom_values" {
  type        = string
  description = "Path to a custom values file to override default ArgoCD configuration values."
  default     = null
}

variable "deploy_argocd" {
  type        = bool
  description = "Flag to determine whether to deploy ArgoCD."
  default     = true
}

variable "argocd_app_repo_username" {
  type        = string
  description = "Username for the ArgoCD application repository."
}

variable "argocd_app_repo_password" {
  type        = string
  description = "Password for the ArgoCD application repository."
  default     = "password"
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "dev-interop-experimental-argocd"
    ManagedBy   = "Terraform"
    Purpose     = "ArgoCD-Dev-Interop-Experimental"
  }
  description = "Tags to apply to resources"
}

variable "password_seed" {
  type        = string
  description = "Seed value to keep the generated password stable across applies"
  default     = "argocd-admin-password-v1"
}
variable "eks_cluster_name" {
  type        = string
  description = "EKS cluster name for the module configuration"
  default     = "interop-eks-cluster-dev"
}

variable "resource_prefix" {
  type        = string
  description = "Resource prefix used for resource naming"
  default     = "dev-interop"
}

variable "create_argocd_project" {
  type        = bool
  description = "Flag to determine whether to create an ArgoCD AppProject"
  default     = true
}

variable "create_argocd_rbac" {
  type        = bool
  description = "Flag to determine whether to create ClusterRole and ClusterRoleBinding for ArgoCD"
  default     = true
}
