
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
  type        = string
  description = "Environment name"
}

variable "tags" {
  description = "Tags to apply to all resources."
  type        = map(string)
  default     = {}
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

variable "enable_mutual_cert_vpn" {
  description = "Create the mutual-cert VPN endpoint."
  type        = bool
  default     = true
}

variable "enable_saml_vpn" {
  description = "Create the SAML VPN endpoint."
  type        = bool
  default     = false
}

variable "mutual_cert_vpn_type" {
  description = "VPN type used by the mutual-cert module instance."
  type        = string
  default     = "mutual-cert"
}

variable "saml_vpn_type" {
  description = "VPN type used by the SAML module instance."
  type        = string
  default     = "saml"
}

variable "create_test_network" {
  description = "Create the test VPC/subnet/IGW/route table in this root."
  type        = bool
  default     = true
}

variable "vpn_vpc_id" {
  description = "Existing VPC ID to use when create_test_network is false."
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
  description = "Mutual-cert client CIDR"
  type        = string
  default     = "10.100.0.0/22"
}

variable "vpn_saml_client_cidr" {
  description = "SAML client CIDR"
  type        = string
  default     = "10.101.0.0/22"
}

variable "mutual_cert_subnet_ids" {
  description = "Subnet IDs for the mutual-cert endpoint."
  type        = list(string)
  default     = []
}

variable "saml_subnet_ids" {
  description = "Subnet IDs for the SAML endpoint."
  type        = list(string)
  default     = []
}

variable "keycloak_realm" {
  description = "Keycloak realm for SAML metadata fetch."
  type        = string
  default     = ""
}

variable "saml_metadata_xml" {
  description = "Raw SAML metadata XML."
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

variable "cert_validity_hours" {
  description = "Certificate validity in hours."
  type        = number
  default     = 8760
}

variable "admin_key_version" {
  description = "Admin key write-only version."
  type        = number
  default     = 1
}

variable "admin_cert_version" {
  description = "Admin cert write-only version."
  type        = number
  default     = 1
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

variable "create_secrets" {
  description = "Create Secrets Manager secrets."
  type        = bool
  default     = true
}

variable "secret_recovery_window_days" {
  description = "Recovery window in days for Secrets Manager secrets on deletion. Use 0 for immediate deletion in test environments."
  type        = number
  default     = 0
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

variable "saml_group" {
  description = "Allowed SAML group."
  type        = string
  default     = ""
}
