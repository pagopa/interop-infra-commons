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

variable "deploy_argocd" {
  type        = bool
  description = "Flag to determine whether to deploy ArgoCD."
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
  description = "Optional override: bcrypt hash of ArgoCD admin password. If provided, AWS Secrets Manager resources are skipped."
  default     = null
}

variable "argocd_admin_password_mtime" {
  type        = string
  description = "Optional override: mtime string for ArgoCD admin password secret (e.g., RFC3339). If provided, AWS time_static is skipped."
  default     = null
}

variable "microservices_plugin_name" {
  type        = string
  description = "Name of the microservices plugin container"
  default     = "argocd-plugin-microservices"
}

variable "microservices_plugin_image_prefix" {
  type        = string
  description = "Image registry prefix for microservices plugin"
  default     = ""
}

variable "microservices_plugin_image_name" {
  type        = string
  description = "Image name for microservices plugin"
  default     = "argocd-plugin-microservices"
}

variable "microservices_plugin_image_tag" {
  type        = string
  description = "Image tag for microservices plugin"
  default     = "local"
}

variable "cronjobs_plugin_name" {
  type        = string
  description = "Name of the cronjobs plugin container"
  default     = "argocd-plugin-cronjobs"
}

variable "cronjobs_plugin_image_prefix" {
  type        = string
  description = "Image registry prefix for cronjobs plugin"
  default     = ""
}

variable "cronjobs_plugin_image_name" {
  type        = string
  description = "Image name for cronjobs plugin"
  default     = "argocd-plugin-cronjobs"
}

variable "cronjobs_plugin_image_tag" {
  type        = string
  description = "Image tag for cronjobs plugin"
  default     = "local"
}


#variable "aws_lb_controller_role_name" {
#  type        = string
#  description = "Name of the IAM role to be assumed by the AWS Load Balancer Controller service account"
#}

#variable "aws_lb_controller_chart_version" {
#  type        = string
#  description = "Chart version for AWS Load Balancer Controller"
#}

#variable "aws_lb_controller_replicas" {
#  type        = number
#  description = "Replica count for AWS Load Balancer Controller"
#}

#variable "vpn_clients_security_group_id" {
#  type        = string
#  description = "ID of the VPN clients SG"
#}
