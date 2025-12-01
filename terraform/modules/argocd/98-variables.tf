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

variable "controller_replicas" {
  type        = number
  description = "Number of replicas for controller"
  default     = null
}

variable "reposerver_replicas" {
  type        = number
  description = "Number of replicas for repo-server"
  default     = null
}

variable "server_replicas" {
  type        = number
  description = "Number of replicas for server"
  default     = null
}

variable "controller_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for controller"
  default     = null
}

variable "reposerver_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for repo-server"
  default     = null
}

variable "server_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for server"
  default     = null
}

variable "redis_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for redis"
  default     = null
}

variable "applicationset_replicas" {
  type        = number
  description = "Number of replicas for applicationset"
  default     = null
}

variable "applicationset_resources" {
  type = object({
    limits = object({
      cpu    = string
      memory = string
    })
    requests = object({
      cpu    = string
      memory = string
    })
  })
  description = "Resource limits and requests for applicationset"
  default     = null
}
