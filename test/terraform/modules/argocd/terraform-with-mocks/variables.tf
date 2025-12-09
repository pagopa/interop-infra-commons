variable "aws_region" {
  type        = string
  description = "AWS region (mock per testing locale)"
  default     = "eu-south-1"
}

variable "env" {
  type        = string
  description = "Environment name"
  default     = "local-test"
}

variable "argocd_namespace" {
  type        = string
  description = "Kubernetes namespace where ArgoCD will be deployed."
  default     = "argocd"
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
  description = "Username for the ArgoCD application repository (mock)."
  default     = "admin"
}

variable "argocd_app_repo_password" {
  type        = string
  description = "Password for the ArgoCD application repository (mock)."
  default     = "password"
  sensitive   = true
}

variable "tags" {
  type = map(string)
  default = {
    Environment = "local-test"
    ManagedBy   = "Terraform"
    Purpose     = "ArgoCD-Testing"
  }
  description = "Tags to apply to resources"
}

variable "password_seed" {
  type        = string
  description = "Seed value to keep the generated password stable across applies"
  default     = "argocd-admin-password-v1"
}
