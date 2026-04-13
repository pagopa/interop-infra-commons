variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "app_name" {
  description = "Application name"
  type        = string
  default     = "interop-vpn-test"
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "create_mutual_cert_vpn" {
  description = "Create the mutual-cert VPN endpoint."
  type        = bool
  default     = true
}

variable "create_saml_vpn" {
  description = "Create the SAML VPN endpoint."
  type        = bool
  default     = false
}

variable "create_networking_resources" {
  description = "If true, creates VPC/subnet/IGW/route table in this root. Set to false to use an existing VPC."
  type        = bool
  default     = true
}

variable "vpn_vpc_id" {
  description = "Existing VPC ID to use when create_networking_resources is false."
  type        = string
  default     = null
}

variable "vpc_cidr" {
  description = "Test VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "Test subnet CIDR block"
  type        = string
  default     = "10.0.1.0/24"
}

variable "vpn_client_cidr" {
  description = "VPN client CIDR"
  type        = string
  default     = "10.100.0.0/22"
}

variable "subnet_ids" {
  description = "Subnet IDs for the VPN endpoint."
  type        = list(string)
  default     = []

  validation {
    condition     = !var.create_network_associations || var.create_networking_resources || length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID when create_network_associations is true and create_networking_resources is false."
  }
}

variable "create_network_associations" {
  description = "Create subnet associations for the mutual-cert VPN endpoint."
  type        = bool
  default     = true
}

variable "saml_metadata_xml" {
  description = "Raw SAML metadata XML."
  type        = string
  default     = ""

  validation {
    condition = (
      !var.create_saml_vpn ||
      !var.create_saml_provider ||
      try(trimspace(var.saml_metadata_xml), "") != "" ||
      var.saml_metadata_url != null
    )
    error_message = "When create_saml_vpn is true and create_saml_provider is true, provide saml_metadata_xml or saml_metadata_url."
  }
}

variable "saml_metadata_url" {
  description = "URL used to fetch SAML metadata XML when saml_metadata_xml is empty."
  type        = string
  default     = null
}

variable "create_saml_provider" {
  description = "Create the IAM SAML provider."
  type        = bool
  default     = true
}

variable "existing_saml_provider_arn" {
  description = "ARN of an existing IAM SAML provider."
  type        = string
  default     = null

  validation {
    condition = (
      !var.create_saml_vpn ||
      var.create_saml_provider ||
      var.existing_saml_provider_arn != null
    )
    error_message = "existing_saml_provider_arn must be provided when create_saml_vpn is true and create_saml_provider is false."
  }
}

variable "dns_servers" {
  description = "DNS servers for VPN clients."
  type        = list(string)
  default     = null
}

variable "split_tunnel" {
  description = "Enable split tunnel."
  type        = bool
  default     = true
}

variable "transport_protocol" {
  description = "VPN transport protocol."
  type        = string
  default     = "udp"
}

variable "vpn_port" {
  description = "VPN port."
  type        = number
  default     = 443
}

variable "connection_log_enabled" {
  description = "Enable VPN connection logs."
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "Log retention in days."
  type        = number
  default     = 30
}

variable "create_security_group" {
  description = "Create the VPN security group."
  type        = bool
  default     = true
}

variable "external_security_group_ids" {
  description = "Existing security group IDs."
  type        = list(string)
  default     = []
}

variable "security_group_name" {
  description = "Security group name."
  type        = string
  default     = null
}

variable "security_group_tag_name" {
  description = "Name tag value for the security group."
  type        = string
  default     = null
}

variable "security_group_description" {
  description = "Security group description."
  type        = string
  default     = "Security group for Client VPN endpoint"
}

variable "egress_ipv4_cidr" {
  description = "IPv4 CIDR allowed in the default egress rule."
  type        = string
  default     = "0.0.0.0/0"
}

variable "egress_rule_description" {
  description = "Description for the default egress rule."
  type        = string
  default     = "Allow all outbound traffic"
}

variable "create_log_group" {
  description = "Create the CloudWatch log group."
  type        = bool
  default     = true
}

variable "external_log_group_name" {
  description = "Existing CloudWatch log group name."
  type        = string
  default     = null
}

variable "log_group_name" {
  description = "CloudWatch log group name."
  type        = string
  default     = null
}

variable "log_group_tag_name" {
  description = "Name tag value for the CloudWatch log group."
  type        = string
  default     = null
}

variable "session_timeout_hours" {
  description = "VPN session timeout in hours."
  type        = number
  default     = 8
}

variable "self_service_portal" {
  description = "Self-service portal status."
  type        = string
  default     = "disabled"
}

variable "server_certificate_arn" {
  description = "ACM server certificate ARN."
  type        = string
  nullable    = false
}

variable "client_ca_certificate_arn" {
  description = "ACM client CA certificate ARN. Required when create_mutual_cert_vpn is true."
  type        = string
  default     = null

  validation {
    condition     = !var.create_mutual_cert_vpn || var.client_ca_certificate_arn != null
    error_message = "client_ca_certificate_arn must be provided when create_mutual_cert_vpn is true."
  }
}

variable "mutual_cert_endpoint_description" {
  description = "Description for the mutual-cert VPN endpoint."
  type        = string
  default     = null
}

variable "mutual_cert_endpoint_tag_name" {
  description = "Name tag value for the mutual-cert VPN endpoint."
  type        = string
  default     = null
}

variable "saml_endpoint_description" {
  description = "Description for the SAML VPN endpoint."
  type        = string
  default     = null
}

variable "saml_endpoint_tag_name" {
  description = "Name tag value for the SAML VPN endpoint."
  type        = string
  default     = null
}

variable "authorization_target_network_cidr" {
  description = "CIDR used by authorization rules."
  type        = string
  default     = null
}

variable "mutual_cert_authorization_rule_description" {
  description = "Description for the mutual-cert authorization rule."
  type        = string
  default     = null
}

variable "saml_authorization_rule_description" {
  description = "Description for the SAML authorization rule."
  type        = string
  default     = null
}

variable "saml_provider_name" {
  description = "IAM SAML provider name."
  type        = string
  default     = null
}

variable "saml_provider_tag_name" {
  description = "Name tag value for the IAM SAML provider."
  type        = string
  default     = null
}

variable "saml_group" {
  description = "SAML group ID allowed through the VPN."
  type        = string
  default     = ""
}
