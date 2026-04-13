module "vpn_mutual_cert" {
  # source = "git::https://github.com/pagopa/interop-infra-commons.git//terraform/modules/vpn?ref=<branch-or-tag>"
  source = "../terraform/modules/vpn"
  count  = var.create_mutual_cert_vpn ? 1 : 0

  app_name = var.app_name
  env      = var.env
  vpn_type = "mutual-cert"
  tags     = var.tags

  vpc_id                      = local.resolved_vpc_id
  vpc_cidr                    = var.vpc_cidr
  subnet_ids                  = local.endpoint_subnet_ids
  create_network_associations = var.create_network_associations
  vpn_client_cidr             = var.vpn_client_cidr
  dns_servers                 = var.dns_servers
  split_tunnel                = var.split_tunnel
  transport_protocol          = var.transport_protocol
  vpn_port                    = var.vpn_port

  create_security_group       = var.create_security_group
  external_security_group_ids = var.external_security_group_ids
  security_group_name         = var.security_group_name
  security_group_tag_name     = var.security_group_tag_name
  security_group_description  = var.security_group_description
  egress_ipv4_cidr            = var.egress_ipv4_cidr
  egress_rule_description     = var.egress_rule_description
  create_log_group            = var.create_log_group
  external_log_group_name     = var.external_log_group_name
  log_group_name              = var.log_group_name
  log_group_tag_name          = var.log_group_tag_name

  connection_log_enabled            = var.connection_log_enabled
  cloudwatch_log_retention_days     = var.cloudwatch_log_retention_days
  session_timeout_hours             = var.session_timeout_hours
  self_service_portal               = var.self_service_portal
  endpoint_description              = var.mutual_cert_endpoint_description
  vpn_endpoint_tag_name             = var.mutual_cert_endpoint_tag_name
  authorization_target_network_cidr = var.authorization_target_network_cidr
  authorization_rule_description    = var.mutual_cert_authorization_rule_description

  server_certificate_arn    = var.server_certificate_arn
  client_ca_certificate_arn = var.client_ca_certificate_arn
}

module "vpn_saml" {
  # source = "git::https://github.com/pagopa/interop-infra-commons.git//terraform/modules/vpn?ref=<branch-or-tag>"
  source = "../terraform/modules/vpn"
  count  = var.create_saml_vpn ? 1 : 0

  app_name = var.app_name
  env      = var.env
  vpn_type = "saml"
  tags     = var.tags

  vpc_id                      = local.resolved_vpc_id
  vpc_cidr                    = var.vpc_cidr
  subnet_ids                  = local.endpoint_subnet_ids
  create_network_associations = true
  vpn_client_cidr             = var.vpn_client_cidr
  dns_servers                 = var.dns_servers
  split_tunnel                = var.split_tunnel
  transport_protocol          = var.transport_protocol
  vpn_port                    = var.vpn_port

  create_security_group       = var.create_security_group
  external_security_group_ids = var.external_security_group_ids
  security_group_name         = var.security_group_name
  security_group_tag_name     = var.security_group_tag_name
  security_group_description  = var.security_group_description
  egress_ipv4_cidr            = var.egress_ipv4_cidr
  egress_rule_description     = var.egress_rule_description
  create_log_group            = var.create_log_group
  external_log_group_name     = var.external_log_group_name
  log_group_name              = var.log_group_name
  log_group_tag_name          = var.log_group_tag_name

  connection_log_enabled            = var.connection_log_enabled
  cloudwatch_log_retention_days     = var.cloudwatch_log_retention_days
  session_timeout_hours             = var.session_timeout_hours
  self_service_portal               = var.self_service_portal
  endpoint_description              = var.saml_endpoint_description
  vpn_endpoint_tag_name             = var.saml_endpoint_tag_name
  authorization_target_network_cidr = var.authorization_target_network_cidr
  authorization_rule_description    = var.saml_authorization_rule_description

  server_certificate_arn = var.server_certificate_arn

  saml_metadata_xml          = local.saml_metadata_xml
  saml_group                 = var.saml_group
  create_saml_provider       = var.create_saml_provider
  existing_saml_provider_arn = var.existing_saml_provider_arn
  saml_provider_name         = var.saml_provider_name
  saml_provider_tag_name     = var.saml_provider_tag_name
}
