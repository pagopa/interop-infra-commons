variable "env" {
  type        = string
  description = "Environment name"
}

variable "ses_identity_name" {
  description = "Name of the SES Identity to create. It can be either an email address or a domain"
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of the hosted zone in which records will be created for DKIM and SPF authentication purposes"
  type        = string
}

variable "create_alarms" {
  description = "If true, CloudWatch alarms are created for Reject, Bounce and Complaint metrics"
  type        = bool
}

variable "sns_topics_arn" {
  description = "List of SNS topic ARNs in which CloudWatch will publish a message when the Reject Alarm is triggered. It must not be null if create_alarms is true."
  type        = list(string)
  default     = null
}

variable "ses_reputation_sns_topics_arn" {
  description = "List of SNS topic ARNs in which CloudWatch will publish a message when the Reputation Alarms (Bounce and Complaint) are triggered. It must not be null if create_alarms is true."
  type        = list(string)
  default     = null
}