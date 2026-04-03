
resource "aws_security_group" "vpn" {
  count       = var.create_security_group ? 1 : 0
  name        = local.resolved_security_group_name
  description = local.resolved_security_group_description
  vpc_id      = var.vpc_id
  tags        = merge(var.tags, { Name = local.resolved_security_group_tag_name })
}

resource "aws_vpc_security_group_egress_rule" "vpn_all" {
  count             = var.create_security_group ? 1 : 0
  security_group_id = aws_security_group.vpn[0].id
  ip_protocol       = "-1"
  cidr_ipv4         = var.egress_ipv4_cidr
  description       = local.resolved_egress_rule_description
}

resource "aws_cloudwatch_log_group" "vpn" {
  count             = var.connection_log_enabled && var.create_log_group ? 1 : 0
  name              = local.resolved_log_group_name
  retention_in_days = var.cloudwatch_log_retention_days
  tags              = merge(var.tags, { Name = local.resolved_log_group_tag_name })
}

locals {
  auth_options = local.is_mutual_cert ? [
    {
      type                           = "certificate-authentication"
      root_certificate_chain_arn     = local.client_ca_cert_arn
      saml_provider_arn              = null
      self_service_saml_provider_arn = null
    }
    ] : [
    {
      type                           = "federated-authentication"
      root_certificate_chain_arn     = null
      saml_provider_arn              = local.saml_provider_arn
      self_service_saml_provider_arn = local.saml_provider_arn
    }
  ]
}

resource "aws_ec2_client_vpn_endpoint" "this" {
  description            = local.resolved_endpoint_description
  client_cidr_block      = var.vpn_client_cidr
  server_certificate_arn = local.server_cert_arn
  split_tunnel           = var.split_tunnel
  self_service_portal    = var.self_service_portal
  transport_protocol     = var.transport_protocol
  vpn_port               = var.vpn_port
  session_timeout_hours  = var.session_timeout_hours
  dns_servers            = local.dns_servers
  security_group_ids     = local.security_group_ids
  vpc_id                 = var.vpc_id

  dynamic "authentication_options" {
    for_each = local.auth_options
    content {
      type                           = authentication_options.value.type
      root_certificate_chain_arn     = authentication_options.value.root_certificate_chain_arn
      saml_provider_arn              = authentication_options.value.saml_provider_arn
      self_service_saml_provider_arn = authentication_options.value.self_service_saml_provider_arn
    }
  }

  connection_log_options {
    enabled              = var.connection_log_enabled
    cloudwatch_log_group = var.connection_log_enabled ? local.log_group_name : null
  }

  tags = merge(var.tags, { Name = local.resolved_endpoint_tag_name })
}

resource "aws_ec2_client_vpn_network_association" "this" {
  for_each               = var.create_network_associations ? local.subnet_ids_by_index : {}
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  subnet_id              = each.value
}

resource "aws_ec2_client_vpn_authorization_rule" "mutual_cert" {
  count                  = local.is_mutual_cert ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = local.authorization_target_network_cidr
  authorize_all_groups   = true
  description            = local.resolved_authorization_rule_description
}

resource "aws_ec2_client_vpn_authorization_rule" "saml" {
  count                  = local.is_saml ? 1 : 0
  client_vpn_endpoint_id = aws_ec2_client_vpn_endpoint.this.id
  target_network_cidr    = local.authorization_target_network_cidr
  authorize_all_groups   = var.saml_group == "" ? true : null
  access_group_id        = var.saml_group != "" ? var.saml_group : null
  description            = local.resolved_authorization_rule_description
}
