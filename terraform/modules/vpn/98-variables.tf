
variable "app_name" {
  description = "Application / project name used as prefix for resources"
  type        = string
}

variable "env" {
  type        = string
  description = "Environment name"
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

variable "name_prefix_override" {
  description = "Override for the base resource name prefix."
  type        = string
  default     = null
}

variable "endpoint_name_prefix_override" {
  description = "Override for the endpoint resource name prefix."
  type        = string
  default     = null
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
}

variable "saml_group" {
  description = "SAML group ID allowed through the VPN (required for saml mode)"
  type        = string
  default     = ""
}

variable "create_saml_provider" {
  description = "Create the IAM SAML provider."
  type        = bool
  default     = true
}

variable "external_saml_provider_arn" {
  description = "Existing IAM SAML provider ARN."
  type        = string
  default     = null
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

variable "cert_validity_hours" {
  description = "Validity period for TLS certificates in hours"
  type        = number
  default     = 8760 # 1 year
}

variable "admin_key_version" {
  description = "Increment to trigger write-only admin key rotation in Secrets Manager"
  type        = number
  default     = 1
}

variable "admin_cert_version" {
  description = "Increment to trigger write-only admin cert rotation in Secrets Manager"
  type        = number
  default     = 1
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
  description = "Override for the security group name."
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
  description = "Override for the log group name."
  type        = string
  default     = null
}

variable "external_server_certificate_arn" {
  description = "Existing ACM server certificate ARN."
  type        = string
  default     = null
}

variable "external_client_ca_certificate_arn" {
  description = "Existing ACM client CA certificate ARN."
  type        = string
  default     = null
}

variable "external_client_ca_cert_pem" {
  description = "External client CA certificate PEM used to locally sign admin client certificates."
  type        = string
  default     = null
}

variable "external_client_ca_private_key_pem" {
  description = "External client CA private key PEM used to locally sign admin client certificates."
  type        = string
  default     = null
  sensitive   = true
}

variable "external_client_admin_key_secret_arn" {
  description = "ARN of an existing Secrets Manager secret containing the client admin private key PEM."
  type        = string
  default     = null
}

variable "external_server_key_secret_arn" {
  description = "ARN of an existing Secrets Manager secret containing the server private key PEM."
  type        = string
  default     = null
}

variable "create_secrets" {
  description = "Create Secrets Manager secrets."
  type        = bool
  default     = true
}

variable "secret_recovery_window_days" {
  description = "Recovery window in days for Secrets Manager secrets on deletion. Set to 0 for immediate deletion (useful in test environments)."
  type        = number
  default     = 7
  validation {
    condition     = var.secret_recovery_window_days == 0 || (var.secret_recovery_window_days >= 7 && var.secret_recovery_window_days <= 30)
    error_message = "secret_recovery_window_days must be 0 (immediate) or between 7 and 30."
  }
}

variable "secret_name_prefix" {
  description = "Secrets Manager name prefix."
  type        = string
  default     = null
}

variable "server_ca_common_name" {
  description = "Server CA certificate common name."
  type        = string
  default     = null
}

variable "server_common_name" {
  description = "Server certificate common name."
  type        = string
  default     = null
}

variable "client_ca_common_name" {
  description = "Client CA certificate common name."
  type        = string
  default     = null
}

variable "client_admin_common_name" {
  description = "Admin client certificate common name."
  type        = string
  default     = null
}

variable "endpoint_description" {
  description = "Override for the VPN endpoint description."
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
  default     = "Allow all cert-authenticated clients to access VPC"
}

variable "saml_authorization_rule_description" {
  description = "Description for the SAML authorization rule."
  type        = string
  default     = null
}

variable "saml_provider_name" {
  description = "Override for the IAM SAML provider name."
  type        = string
  default     = null
}
