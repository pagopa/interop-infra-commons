variable "env" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "clients_diff_image_tag" {
  description = "Image tag for vpn-clients-diff repository"
  type        = string
}

variable "clients_updater_image_tag" {
  description = "Image tag for vpn-clients-updater repository"
  type        = string
}

variable "lambda_function_subnets_ids" {
  description = "AWS Lambda Subnets ids"
  type        = set(string)
}

variable "efs_clients_security_groups_ids" {
  description = "AWS EFS Subnets ids"
  type        = set(string)
}

variable "mount_target_subnets_ids" {
  description = "AWS EFS Mount Target Subnets ids"
  type        = set(string)
}

variable "vpn_endpoint_id" {
  description = "VPN Endpoint id"
  type        = string
}

variable "vpc_id" {
  description = "VPC id"
  type        = string
}

variable "client_vpn_endpoint_arn" {
  description = "Client VPN Endpoint ARN"
  type        = string
}

variable "ses_configuration_set_name" {
  description = "SES Configuration set name"
  type        = string
}

variable "ses_from_address" {
  description = "SES From Address"
  type        = string
}

variable "ses_from_display_name" {
  description = "SES From Display Name"
  type        = string
}

variable "ses_mail_subject" {
  description = "SES Email Subject"
  type        = string
}

variable "efs_pki_directory" {
  description = "EASYRSA EFS pki directory"
  type        = string
}
