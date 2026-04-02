module "vpn_mutual_cert" {
  count = var.enable_mutual_cert_vpn ? 1 : 0
  # source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/vpn?ref=<branch-or-tag>"
  source = "../terraform/modules/vpn"

  app_name                      = var.app_name
  env                           = var.env
  vpn_type                      = var.mutual_cert_vpn_type
  tags                          = var.tags
  name_prefix_override          = var.name_prefix_override
  endpoint_name_prefix_override = var.endpoint_name_prefix_override

  vpc_id             = local.resolved_vpc_id
  vpc_cidr           = var.vpc_cidr
  subnet_ids         = local.mutual_cert_subnet_ids
  vpn_client_cidr    = var.vpn_client_cidr
  dns_servers        = var.dns_servers
  split_tunnel       = var.split_tunnel
  transport_protocol = var.transport_protocol
  vpn_port           = var.vpn_port

  create_security_group       = var.create_security_group
  external_security_group_ids = var.external_security_group_ids
  security_group_name         = var.security_group_name
  security_group_description  = var.security_group_description
  egress_ipv4_cidr            = var.egress_ipv4_cidr
  egress_rule_description     = var.egress_rule_description
  create_log_group            = var.create_log_group
  external_log_group_name     = var.external_log_group_name
  log_group_name              = var.log_group_name

  connection_log_enabled                     = var.connection_log_enabled
  cloudwatch_log_retention_days              = var.cloudwatch_log_retention_days
  session_timeout_hours                      = var.session_timeout_hours
  self_service_portal                        = var.self_service_portal
  endpoint_description                       = var.endpoint_description
  authorization_target_network_cidr          = var.authorization_target_network_cidr
  mutual_cert_authorization_rule_description = var.mutual_cert_authorization_rule_description

  cert_validity_hours                = var.cert_validity_hours
  admin_key_version                  = var.admin_key_version
  admin_cert_version                 = var.admin_cert_version
  external_server_certificate_arn    = var.external_server_certificate_arn
  external_client_ca_certificate_arn = var.external_client_ca_certificate_arn
  external_client_ca_cert_pem        = var.external_client_ca_cert_pem
  external_client_ca_private_key_pem = var.external_client_ca_private_key_pem
  create_secrets                     = var.create_secrets
  secret_name_prefix                 = var.secret_name_prefix
  server_ca_common_name              = var.server_ca_common_name
  server_common_name                 = var.server_common_name
  client_ca_common_name              = var.client_ca_common_name
  client_admin_common_name           = var.client_admin_common_name
}

module "vpn_saml" {
  count = local.is_saml ? 1 : 0
  # source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/vpn?ref=<branch/tag>"
  source = "../terraform/modules/vpn"

  app_name                      = "${var.app_name}-saml"
  env                           = var.env
  vpn_type                      = var.saml_vpn_type
  tags                          = var.tags
  name_prefix_override          = var.name_prefix_override
  endpoint_name_prefix_override = var.endpoint_name_prefix_override

  vpc_id             = local.resolved_vpc_id
  vpc_cidr           = var.vpc_cidr
  subnet_ids         = local.saml_subnet_ids
  vpn_client_cidr    = var.vpn_saml_client_cidr
  dns_servers        = var.dns_servers
  split_tunnel       = var.split_tunnel
  transport_protocol = var.transport_protocol
  vpn_port           = var.vpn_port

  saml_metadata_xml                   = local.saml_metadata_xml
  saml_group                          = var.saml_group
  create_saml_provider                = var.create_saml_provider
  external_saml_provider_arn          = var.external_saml_provider_arn
  saml_provider_name                  = var.saml_provider_name
  saml_authorization_rule_description = var.saml_authorization_rule_description

  create_security_group       = var.create_security_group
  external_security_group_ids = var.external_security_group_ids
  security_group_name         = var.security_group_name
  security_group_description  = var.security_group_description
  egress_ipv4_cidr            = var.egress_ipv4_cidr
  egress_rule_description     = var.egress_rule_description
  create_log_group            = var.create_log_group
  external_log_group_name     = var.external_log_group_name
  log_group_name              = var.log_group_name

  cloudwatch_log_retention_days   = var.cloudwatch_log_retention_days
  cert_validity_hours             = var.cert_validity_hours
  external_server_certificate_arn = var.external_server_certificate_arn
  secret_name_prefix              = var.secret_name_prefix
  server_ca_common_name           = var.server_ca_common_name
  server_common_name              = var.server_common_name

  connection_log_enabled            = var.connection_log_enabled
  session_timeout_hours             = var.session_timeout_hours
  self_service_portal               = var.self_service_portal
  endpoint_description              = var.endpoint_description
  authorization_target_network_cidr = var.authorization_target_network_cidr
}
