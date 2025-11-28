variable "aws_region" {
  type        = string
  description = "AWS region"
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
  description = "Name of the EKS cluster accessing the analytics cluster"
}

variable "argocd_custom_values" {
  type        = string
  description = "Path to a custom values file to override default ArgoCD configuration values."
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

variable "deploy_argocd" {
  type        = bool
  description = "Flag to determine whether to deploy ArgoCD."
  default     = true
}
