variable "app_name" {
  description = "Application / project name used as base for resource defaults"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "vpn_type" {
  description = "VPN authentication mode: 'mutual-cert' or 'saml'"
  type        = string
  validation {
    condition     = contains(["mutual-cert", "saml"], var.vpn_type)
    error_message = "vpn_type must be 'mutual-cert' or 'saml'."
  }
}

variable "vpc_id" {
  description = "VPC ID to associate with the VPN endpoint"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block of the VPC (used for authorization rules)"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to associate with the VPN endpoint"
  type        = list(string)

  validation {
    condition     = !var.create_network_associations || length(var.subnet_ids) > 0
    error_message = "subnet_ids must contain at least one subnet ID."
  }
}

variable "create_network_associations" {
  description = "Create subnet associations for the VPN endpoint in mutual-cert mode."
  type        = bool
  default     = true

  validation {
    condition     = var.vpn_type == "mutual-cert" || var.create_network_associations
    error_message = "create_network_associations can be set to false only when vpn_type is 'mutual-cert'."
  }
}

variable "vpn_client_cidr" {
  description = "CIDR block for VPN client addresses (must not overlap with VPC CIDR)"
  type        = string
  default     = "10.200.0.0/16"
}

variable "saml_metadata_xml" {
  description = "Raw XML SAML metadata from the IdP"
  type        = string
  default     = ""

  validation {
    condition = (
      var.vpn_type != "saml" ||
      !var.create_saml_provider ||
      try(trimspace(var.saml_metadata_xml), "") != ""
    )
    error_message = "saml_metadata_xml must be provided when vpn_type is 'saml' and create_saml_provider is true."
  }
}

variable "saml_group" {
  description = "SAML group ID allowed through the VPN"
  type        = string
  default     = ""
}

variable "create_saml_provider" {
  description = "Create the IAM SAML provider."
  type        = bool
  default     = true

  validation {
    condition     = var.vpn_type == "saml" || var.create_saml_provider
    error_message = "create_saml_provider can be set to false only when vpn_type is 'saml'."
  }
}

variable "existing_saml_provider_arn" {
  description = "ARN of an existing IAM SAML provider."
  type        = string
  default     = null

  validation {
    condition = (
      var.vpn_type != "saml" ||
      var.create_saml_provider ||
      var.existing_saml_provider_arn != null
    )
    error_message = "existing_saml_provider_arn must be provided when vpn_type is 'saml' and create_saml_provider is false."
  }
}

variable "dns_servers" {
  description = "List of DNS server IPs for VPN clients. Defaults to AmazonProvidedDNS (VPC base +2)."
  type        = list(string)
  default     = null
}

variable "split_tunnel" {
  description = "Enable split tunnel (only VPC traffic through the VPN)"
  type        = bool
  default     = true
}

variable "transport_protocol" {
  description = "Transport protocol: 'udp' or 'tcp'"
  type        = string
  default     = "udp"
  validation {
    condition     = contains(["udp", "tcp"], var.transport_protocol)
    error_message = "transport_protocol must be 'udp' or 'tcp'."
  }
}

variable "vpn_port" {
  description = "Port for the VPN endpoint (443 or 1194)"
  type        = number
  default     = 443
  validation {
    condition     = contains([443, 1194], var.vpn_port)
    error_message = "vpn_port must be 443 or 1194."
  }
}

variable "session_timeout_hours" {
  description = "Maximum VPN session duration in hours"
  type        = number
  default     = 8
}

variable "self_service_portal" {
  description = "Self-service portal status."
  type        = string
  default     = "disabled"
}

variable "connection_log_enabled" {
  description = "Enable VPN connection logging to CloudWatch"
  type        = bool
  default     = true
}

variable "cloudwatch_log_retention_days" {
  description = "CloudWatch log retention in days"
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

variable "server_certificate_arn" {
  description = "ACM server certificate ARN."
  type        = string
  nullable    = false
}

variable "client_ca_certificate_arn" {
  description = "ACM client CA certificate ARN."
  type        = string
  default     = null

  validation {
    condition = (
      var.vpn_type == "mutual-cert" ? var.client_ca_certificate_arn != null : var.client_ca_certificate_arn == null
    )
    error_message = "client_ca_certificate_arn must be provided only for vpn_type = 'mutual-cert'."
  }
}

variable "endpoint_description" {
  description = "VPN endpoint description."
  type        = string
  default     = null
}

variable "vpn_endpoint_tag_name" {
  description = "Name tag value for the VPN endpoint."
  type        = string
  default     = null
}

variable "authorization_target_network_cidr" {
  description = "CIDR used by authorization rules."
  type        = string
  default     = null
}

variable "authorization_rule_description" {
  description = "Description for the authorization rule created for the selected vpn_type."
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
