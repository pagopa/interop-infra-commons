# Core
aws_region = "eu-west-1"

app_name = "interop-vpn"
env      = "dev"

tags = {
  Owner = ""
}


# Networking
create_test_network = true
vpn_vpc_id          = null

vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

# If false, create the vpn endpoint without subnet associations.
create_network_associations = true

vpn_client_cidr = "10.100.0.0/22"
subnet_ids      = []


# Endpoint
# Supported values:
# - "mutual-cert": requires `server_certificate_arn` and `client_ca_certificate_arn`
# - "saml": requires `server_certificate_arn` and either `saml_metadata_xml`, `saml_metadata_url`,
#   or `existing_saml_provider_arn` when `create_saml_provider = false`
vpn_type = "mutual-cert"

# Endpoint networking
dns_servers        = null
split_tunnel       = true
transport_protocol = "udp"
vpn_port           = 443

# Endpoint behavior
session_timeout_hours             = 8
self_service_portal               = "disabled"
endpoint_description              = null
authorization_target_network_cidr = null

# Authorization rule
authorization_rule_description = null

# CloudWatch logging
connection_log_enabled        = false
cloudwatch_log_retention_days = 30

create_log_group        = false
external_log_group_name = null
log_group_name          = null
log_group_tag_name      = null

# Security group
create_security_group       = true
external_security_group_ids = []
security_group_name         = null
security_group_tag_name     = null
egress_ipv4_cidr            = "0.0.0.0/0"
egress_rule_description     = null
security_group_description  = null

# SAML
saml_metadata_xml          = ""
saml_metadata_url          = null
saml_group                 = ""
create_saml_provider       = true
existing_saml_provider_arn = null
saml_provider_name         = null
saml_provider_tag_name     = null

# PKI
# `mutual-cert`:
# - `server_certificate_arn` and `client_ca_certificate_arn` are both required
# `saml`:
# - `server_certificate_arn` is required
# - `client_ca_certificate_arn` must stay null
server_certificate_arn    = null
client_ca_certificate_arn = null

# Resource tags
vpn_endpoint_tag_name = null
