variable "name" {
  type        = string
  description = "Name for the IAM role"
}

variable "description" {
  type        = string
  description = "Description for the IAM role"
  default     = ""
}

variable "conditions" {
  type = list(object({
    test     = string
    variable = string
    values   = list(string)
  }))
  description = "Conditions for the assume role policy (e.g. sub claim). The aud condition is added automatically."
}

variable "ecr_push_repositories" {
  type        = list(string)
  description = "List of ECR repository name patterns the role can push and pull (e.g. ['myapp-be*', 'myapp-frontend']). Also grants CreateRepository and lifecycle management."
  default     = []
}

variable "ecr_pull_repositories" {
  type        = list(string)
  description = "List of ECR repository name patterns the role can pull from (read-only)."
  default     = []
}

variable "statements" {
  type = list(object({
    sid       = optional(string)
    effect    = string
    actions   = list(string)
    resources = list(string)
    conditions = optional(list(object({
      test     = string
      variable = string
      values   = list(string)
    })), [])
  }))
  description = "Additional IAM policy statements. Combined with ECR statements (if any) into a single inline policy."
  default     = []
}

variable "managed_policy_arns" {
  type        = list(string)
  description = "List of managed IAM policy ARNs to attach to the role"
  default     = []
}
