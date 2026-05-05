variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "app_name" {
  description = "Application / project name used as base for resource defaults."
  type        = string
}

variable "env" {
  description = "Environment name."
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "use_mutual_auth" {
  description = "Use mutual certificate authentication."
  type        = bool
  default     = true
}

variable "use_saml_auth" {
  description = "Use SAML federated authentication."
  type        = bool
  default     = false
}

variable "create_networking_resources" {
  description = "Create the test VPC, subnet, internet gateway, route table and route table association."
  type        = bool
  default     = true
}

variable "vpn_vpc_id" {
  description = "Existing VPC ID to use when create_networking_resources is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC."
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR block of the test subnet."
  type        = string
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN client addresses."
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "Subnet IDs to expose to the client-vpn root."
  type        = list(string)
  default     = []
}

variable "create_network_associations" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = bool
  default     = true
}

variable "client_ca_certificate_arn" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "vpn_endpoint_tag_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "endpoint_description" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "authorization_rule_description" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "server_certificate_arn" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "dns_servers" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = list(string)
  default     = null
}

variable "split_tunnel" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = bool
  default     = true
}

variable "transport_protocol" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = "udp"
}

variable "vpn_port" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = number
  default     = 443
}

variable "session_timeout_hours" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = number
  default     = 8
}

variable "self_service_portal" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = "disabled"
}

variable "authorization_target_network_cidr" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "create_security_group" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = bool
  default     = true
}

variable "external_security_group_ids" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = list(string)
  default     = []
}

variable "security_group_description" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "egress_ipv4_cidr" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "egress_rule_description" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "security_group_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "security_group_tag_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "connection_log_enabled" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = bool
  default     = false
}

variable "cloudwatch_log_retention_days" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = number
  default     = 30
}

variable "create_log_group" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = bool
  default     = false
}

variable "external_log_group_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}

variable "log_group_tag_name" {
  description = "Kept for tfvars compatibility with the previous VPN test root."
  type        = string
  default     = null
}
