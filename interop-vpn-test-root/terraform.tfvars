# ─── Core ────────────────────────────────────────────────────────────────────
aws_region = "eu-west-1"
app_name   = "interop-vpn"
env        = "dev"

tags = {
  Owner = ""
}

# ─── Authentication mode ─────────────────────────────────────────────────────
# Exactly one must be true (XOR).
use_mutual_auth = true
use_saml_auth   = false

# ─── Networking ───────────────────────────────────────────────────────────────
# Set create_networking_resources = false and vpn_vpc_id = "<id>" to use an existing VPC.
create_networking_resources = true
vpn_vpc_id                  = null
vpc_cidr                    = "10.0.0.0/16"
subnet_cidr                 = "10.0.1.0/24"

# Set create_network_associations = false to create the endpoint without subnet associations.
create_network_associations = true
vpn_client_cidr             = "10.100.0.0/22"
subnet_ids                  = []

# ─── Mutual-cert settings ─────────────────────────────────────────────────────
# client_ca_certificate_arn required when use_mutual_auth = true.
client_ca_certificate_arn = null

# ─── SAML settings ────────────────────────────────────────────────────────────
# Provide saml_metadata_xml or saml_metadata_url (fetched at plan time).
# Set create_saml_provider = false and existing_saml_provider_arn = "<arn>" to reuse an existing one.
create_saml_provider       = true
existing_saml_provider_arn = null
saml_metadata_xml          = ""
saml_metadata_url          = null
saml_group                 = ""
saml_provider_name         = null
saml_provider_tag_name     = null

# ─── Endpoint naming ──────────────────────────────────────────────────────────
vpn_endpoint_tag_name          = null
endpoint_description           = null
authorization_rule_description = null

# ─── Shared endpoint settings ─────────────────────────────────────────────────
# server_certificate_arn is always required (TLS for the VPN tunnel, independent of auth type).
server_certificate_arn                = null
dns_servers                           = null
split_tunnel                      = true
transport_protocol                = "udp"
vpn_port                          = 443
session_timeout_hours             = 8
self_service_portal               = "disabled"
authorization_target_network_cidr = null

# ─── Security group ───────────────────────────────────────────────────────────
create_security_group       = true
external_security_group_ids = []
security_group_description  = null
egress_ipv4_cidr            = "0.0.0.0/0"
egress_rule_description     = null
security_group_name         = null
security_group_tag_name     = null

# ─── CloudWatch logging ───────────────────────────────────────────────────────
connection_log_enabled        = false
cloudwatch_log_retention_days = 30
create_log_group              = false
external_log_group_name       = null
log_group_name                = null
log_group_tag_name            = null
