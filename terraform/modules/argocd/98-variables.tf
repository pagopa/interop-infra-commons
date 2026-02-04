variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "is_local_testing" {
  type        = bool
  description = "Set to true for local testing with kind/minikube. When false, uses EKS cluster credentials."
  default     = false
}

variable "resource_prefix" {
  type        = string
  description = "Resource prefix used for resource naming"
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

####################
# ArgoCD variables #
####################
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
  default     = false
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

variable "use_aws_secrets_manager" {
  type        = bool
  description = "If true, use AWS Secrets Manager to generate and store admin credentials. If false, use argocd_admin_bcrypt_password and argocd_admin_password_mtime."
  default     = true
}

variable "argocd_admin_bcrypt_password" {
  type        = string
  description = "Optional override: bcrypt hash of ArgoCD admin password. Used only when use_aws_secrets_manager=false."
  default     = ""
}

variable "argocd_admin_password_mtime" {
  type        = string
  description = "Optional override: mtime string for ArgoCD admin password secret (e.g., RFC3339). Used only when use_aws_secrets_manager=false."
  default     = ""
}

variable "argocd_helm_timeout_seconds" {
  type        = number
  description = "Timeout in seconds for Helm operations when deploying ArgoCD."
  default     = 600
}

############################
# ArgoCD Plugins variables #
############################
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
  default     = null
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs for ALB placement"
  default     = [ ]
}

#########################################################
# ArgoCD Project variables                              #
#########################################################

variable "create_argocd_project" {
  type        = bool
  description = "Flag to determine whether to create an ArgoCD AppProject"
  default     = true
}

variable "argocd_project_name" {
  type        = string
  description = "Name of the ArgoCD AppProject"
  default     = "default"
}

variable "argocd_project_description" {
  type        = string
  description = "Description of the ArgoCD AppProject"
  default     = "Default ArgoCD Project"
}

variable "argocd_project_source_repos" {
  type        = list(string)
  description = "List of Git repositories allowed for this project. Use ['*'] to allow all repositories."
  default     = ["*"]
}

variable "argocd_project_source_namespaces" {
  type        = list(string)
  description = "List of source namespaces allowed for this project. Use ['*'] to allow all namespaces."
  default     = ["*"]
}

variable "argocd_project_destinations" {
  type = list(object({
    server    = string
    namespace = string
  }))
  description = "List of destination clusters and namespaces. Use server='https://kubernetes.default.svc' for in-cluster and namespace='*' for all namespaces."
  default = [
    {
      server    = "https://kubernetes.default.svc"
      namespace = "*"
    }
  ]
}

variable "argocd_project_cluster_resource_whitelist" {
  type = list(object({
    group = string
    kind  = string
  }))
  description = "Cluster-scoped resources allowed to be managed. Use [{group='*', kind='*'}] to allow all."
  default = [
    {
      group = "*"
      kind  = "*"
    }
  ]
}

variable "argocd_project_namespace_resource_whitelist" {
  type = list(object({
    group = string
    kind  = string
  }))
  description = "Namespace-scoped resources allowed to be managed. Use [{group='*', kind='*'}] to allow all."
  default = [
    {
      group = "*"
      kind  = "*"
    }
  ]
}

variable "argocd_project_orphaned_resources_warn" {
  type        = bool
  description = "Enable warnings for orphaned resources in the project"
  default     = false
}

variable "argocd_project_roles" {
  type = list(object({
    name        = string
    description = string
    policies    = list(string)
    groups      = optional(list(string), [])
  }))
  description = "List of roles to create for the ArgoCD project"
  default     = []
}

#########################################################
# ArgoCD Repository variables                           #
#########################################################

variable "create_argocd_repository" {
  type        = bool
  description = "Flag to determine whether to create an ArgoCD repository credential"
  default     = true
}

variable "argocd_repository_secret_name" {
  type        = string
  description = "Name of the Kubernetes secret that will store the repository credentials"
  default     = "argocd-repository-creds"
}

variable "argocd_repository_type" {
  type        = string
  description = "Repository type: 'git' or 'helm'"
  default     = "git"
  validation {
    condition     = contains(["git", "helm"], var.argocd_repository_type)
    error_message = "Repository type must be either 'git' or 'helm'."
  }
}

variable "argocd_repository_url" {
  type        = string
  description = "URL of the repository (e.g., https://github.com/myorg/myrepo.git or https://helm.example.com)"
  default     = ""
}

variable "argocd_repository_username" {
  type        = string
  description = "Username for repository authentication (for HTTPS repos)"
  default     = ""
  sensitive   = true
}

variable "argocd_repository_password" {
  type        = string
  description = "Password or personal access token for repository authentication (for HTTPS repos)"
  default     = ""
  sensitive   = true
}

variable "argocd_repository_ssh_private_key" {
  type        = string
  description = "SSH private key for repository authentication (for SSH repos)"
  default     = ""
  sensitive   = true
}

variable "argocd_repository_insecure" {
  type        = bool
  description = "Allow insecure connections (skip TLS verification)"
  default     = false
}

variable "argocd_repository_enable_lfs" {
  type        = bool
  description = "Enable Git LFS for the repository"
  default     = false
}

#########################################################
# ArgoCD RBAC variables                                 #
#########################################################

variable "create_argocd_rbac" {
  type        = bool
  description = "Flag to determine whether to create ClusterRole and ClusterRoleBinding for ArgoCD"
  default     = false
}

variable "argocd_application_controller_sa_name" {
  type        = string
  description = "Name of the ArgoCD Application Controller ServiceAccount"
  default     = "argocd-application-controller"
}

variable "argocd_server_sa_name" {
  type        = string
  description = "Name of the ArgoCD Server ServiceAccount"
  default     = "argocd-server"
}

variable "argocd_repo_server_sa_name" {
  type        = string
  description = "Name of the ArgoCD Repo Server ServiceAccount"
  default     = "argocd-repo-server"
}
