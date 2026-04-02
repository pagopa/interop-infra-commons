# Core
aws_region = "eu-west-1"

app_name = "interop-vpn"
env      = "dev"

tags = {
  Owner = "roberto.mondello@digitouch.it"
}

# Naming
# name_prefix_override: cambia il prefisso base usato da PKI (ACM, CN cert), SAML provider, Secrets Manager.
#   default: "{app_name}-{env}"  →  es. "interop-vpn-dev"
#   esempio: name_prefix_override = "foo-vpn-dev"
#     ACM server cert  → Name: "foo-vpn-dev-server-cert"
#     ACM client CA    → Name: "foo-vpn-dev-client-ca"
#     IAM SAML         → nome: "foo-vpn-dev-saml-provider"
#     SM secret        → path: "foo-vpn-dev/vpn/admin-client-key"
name_prefix_override          = null

# endpoint_name_prefix_override: cambia il prefisso usato da security group, CloudWatch log group e VPN endpoint.
#   default: "{name_prefix}-{vpn_type}"  →  es. "interop-vpn-dev-mutual-cert"
#   esempio: endpoint_name_prefix_override = "foo-vpn-endpoint-dev"
#     Security group   → nome: "foo-vpn-endpoint-dev-vpn"
#     CloudWatch LG    → nome: "/aws/vpn/foo-vpn-endpoint-dev"
#     VPN endpoint     → Name tag: "foo-vpn-endpoint-dev-vpn-endpoint"
endpoint_name_prefix_override = null

# Endpoint
enable_mutual_cert_vpn = true
enable_saml_vpn        = false

mutual_cert_vpn_type = "mutual-cert"
saml_vpn_type        = "saml"

# Networking
create_test_network = true
vpn_vpc_id          = null

vpc_cidr    = "10.0.0.0/16"
subnet_cidr = "10.0.1.0/24"

# VPN client CIDRs
vpn_client_cidr      = "10.100.0.0/22"
vpn_saml_client_cidr = "10.101.0.0/22"

# Endpoint subnet associations
mutual_cert_subnet_ids = []
saml_subnet_ids        = []

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

# Endpoint authorization rules
mutual_cert_authorization_rule_description = "Allow all cert-authenticated clients to access VPC"
saml_authorization_rule_description        = null

# CloudWatch logging
connection_log_enabled        = false
cloudwatch_log_retention_days = 30

# CloudWatch log group:
# - true  => il modulo crea il log group
# - false => usare external_log_group_name
create_log_group        = false
external_log_group_name = null
log_group_name          = null

# Security group:
# - true  => il modulo crea il security group
# - false => usare external_security_group_ids
create_security_group       = true
external_security_group_ids = []
security_group_name         = null
security_group_description  = "Security group for Client VPN endpoint"
egress_ipv4_cidr            = "0.0.0.0/0"
egress_rule_description     = "Allow all outbound traffic"

# Endpoint SAML
keycloak_realm    = ""
saml_metadata_xml = ""
saml_group        = ""

# IAM SAML provider:
# - true  => il modulo crea il provider IAM SAML
# - false => usare external_saml_provider_arn
create_saml_provider       = true
external_saml_provider_arn = null
saml_provider_name         = null

# PKI lifecycle
cert_validity_hours         = 8760
admin_key_version           = 1
admin_cert_version          = 1
create_secrets              = true
secret_recovery_window_days = 0 # 0 = cancellazione immediata (test); 7-30 = recovery window (prod)

# PKI esterna (certificati importati in ACM) - risorse di test
#external_server_certificate_arn    = "arn:aws:acm:eu-west-1:120888772144:certificate/e590cdce-3f54-4ff8-9449-567392ab5bea"
#external_client_ca_certificate_arn = "arn:aws:acm:eu-west-1:120888772144:certificate/fd320da6-d860-4117-99fb-075ca0ddc40c"

external_server_certificate_arn    = null
external_client_ca_certificate_arn = null

external_client_ca_cert_pem        = null
external_client_ca_private_key_pem = null

# client_admin_key e server_key aggiunti su Secrets Manager
external_client_admin_key_secret_arn = "arn:aws:secretsmanager:eu-west-1:120888772144:secret:interop-vpn-dev/vpn/test-external-admin-key-EPP06H"
external_server_key_secret_arn       = "arn:aws:secretsmanager:eu-west-1:120888772144:secret:interop-vpn-dev/vpn/test-external-server-key-AtNtOc"

# PKI naming
secret_name_prefix       = null
server_ca_common_name    = null
server_common_name       = null
client_ca_common_name    = null
client_admin_common_name = null
