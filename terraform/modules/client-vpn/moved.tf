# ─── Moved blocks ────────────────────────────────────────────────────────────
#
# Use these blocks when migrating from a root module that called:
#
#   module "vpn" {
#     source = "..."
#     ...
#   }
#
# to this standalone root module (same state backend).
#
# After running `terraform apply` successfully with 0 changes,
# REMOVE this file and commit.
#
# NOTE: for aws_ec2_client_vpn_network_association, one block per subnet is
# required. Add or remove blocks to match the number of subnets in your state.
# Keys correspond to the index position in the subnet_ids list ("0", "1", ...).
# ─────────────────────────────────────────────────────────────────────────────

# ─── Security group ──────────────────────────────────────────────────────────

moved {
  from = module.vpn.aws_security_group.vpn[0]
  to   = aws_security_group.vpn[0]
}

moved {
  from = module.vpn.aws_vpc_security_group_egress_rule.vpn_all[0]
  to   = aws_vpc_security_group_egress_rule.vpn_all[0]
}

# ─── CloudWatch log group (only if connection_log_enabled = true) ────────────

moved {
  from = module.vpn.aws_cloudwatch_log_group.vpn[0]
  to   = aws_cloudwatch_log_group.vpn[0]
}

# ─── Endpoint ────────────────────────────────────────────────────────────────

moved {
  from = module.vpn.aws_ec2_client_vpn_endpoint.this
  to   = aws_ec2_client_vpn_endpoint.this
}

# ─── Network associations (one block per subnet) ─────────────────────────────

moved {
  from = module.vpn.aws_ec2_client_vpn_network_association.this["0"]
  to   = aws_ec2_client_vpn_network_association.this["0"]
}

# moved {
#   from = module.vpn.aws_ec2_client_vpn_network_association.this["1"]
#   to   = aws_ec2_client_vpn_network_association.this["1"]
# }

# moved {
#   from = module.vpn.aws_ec2_client_vpn_network_association.this["2"]
#   to   = aws_ec2_client_vpn_network_association.this["2"]
# }

# ─── Authorization rule — mutual-cert ────────────────────────────────────────

moved {
  from = module.vpn.aws_ec2_client_vpn_authorization_rule.mutual_cert[0]
  to   = aws_ec2_client_vpn_authorization_rule.mutual_cert[0]
}

# ─── Authorization rule — SAML ───────────────────────────────────────────────

moved {
  from = module.vpn.aws_ec2_client_vpn_authorization_rule.saml[0]
  to   = aws_ec2_client_vpn_authorization_rule.saml[0]
}

# ─── SAML provider ───────────────────────────────────────────────────────────

moved {
  from = module.vpn.aws_iam_saml_provider.idp[0]
  to   = aws_iam_saml_provider.idp[0]
}
