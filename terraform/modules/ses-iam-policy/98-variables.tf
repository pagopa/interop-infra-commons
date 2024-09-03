variable "env" {
  type        = string
  description = "Environment name"
}

variable "ses_iam_policy_name" {
  description = "Name of the IAM policy to be created"
  type        = string
}

variable "ses_identity_arn" {
  description = "ARN of the SES Identity to be used to send emails"
  type        = string
}

variable "ses_configuration_set_arn" {
  description = "ARN of the SES Configuration set to be used to send emails"
  type        = string
}

variable "allowed_recipients_literal" {
  description = "List of recipients to which is allowd to send emails. It must contain the exact literals that make each single recipient (e.g. example@pagopa.it)"
  type        = list(string)
  default     = null
}

variable "allowed_recipients_regex" {
  description = "List of recipients to which is allowd to send emails. It can contain regex with wildcards (e.g. *@pagopa.it)"
  type        = list(string)
  default     = null
}

variable "allowed_from_addresses_literal" {
  description = "List of addresses that are allowed to be used as 'FROM address' when sending emails. It must contain the exact literals that make each FROM adress (e.g. noreply@dev.interop.pagopa.it)"
  type        = list(string)
  default     = null
}

variable "allowed_from_addresses_regex" {
  description = "List of addresses that are allowed to be used as 'FROM address' when sending emails. It can contain regex with wildcards (e.g. *-reports@dev.interop.pagopa.it)"
  type        = list(string)
  default     = null
}

variable "allowed_from_display_names" {
  description = "List of names that are allowed to be used as 'FROM display name' when sending emails"
  type        = list(string)
  default     = null
}

variable "allowed_source_vpcs_id" {
  description = "List of VPC IDs from which it is allowed to send emails"
  type        = list(string)
  default     = null
}
