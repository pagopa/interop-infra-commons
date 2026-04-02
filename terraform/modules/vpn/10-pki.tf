# common

# Repro ephemeral server key:
# ephemeral "tls_private_key" "server" {
#   count     = local.create_server_pki ? 1 : 0
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_private_key" "server" {
#   count     = local.create_server_pki ? 1 : 0
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# Repro ephemeral client key:
# ephemeral "tls_private_key" "client_admin" {
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }

# resource "tls_private_key" "client_admin" {
#   count     = local.generate_client_admin_cert ? 1 : 0
#   algorithm = "RSA"
#   rsa_bits  = 2048
# }


# chiave in state TF (sensitive) - tls_self_signed_cert non supporta wo
# Creata solo quando la PKI server è interna.
resource "tls_private_key" "server_ca" {
  count     = local.create_server_pki ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "server_ca" {
  count = local.create_server_pki ? 1 : 0
  # repro ephemeral:
  # private_key_pem = ephemeral.tls_private_key.server_ca.private_key_pem
  private_key_pem = tls_private_key.server_ca[0].private_key_pem
  subject {
    common_name  = "${local.name_prefix}.server.ca"
    organization = local.name_prefix
  }
  validity_period_hours = var.cert_validity_hours
  is_ca_certificate     = true
  allowed_uses          = ["key_encipherment", "digital_signature", "cert_signing"]
}

resource "tls_cert_request" "server" {
  count           = local.create_server_pki ? 1 : 0
  #private_key_pem = tls_private_key.server[0].private_key_pem

  # Repro ephemeral:
  # private_key_pem = ephemeral.tls_private_key.server[0].private_key_pem

  # Repro SM:
  private_key_pem = data.aws_secretsmanager_secret_version.server_key_external[0].secret_string


  subject {
    common_name  = "${local.name_prefix}.server"
    organization = local.name_prefix
  }
  dns_names = ["${local.name_prefix}.server"]
}

resource "tls_locally_signed_cert" "server" {
  count                 = local.create_server_pki ? 1 : 0
  cert_request_pem      = tls_cert_request.server[0].cert_request_pem
  ca_private_key_pem    = tls_private_key.server_ca[0].private_key_pem
  ca_cert_pem           = tls_self_signed_cert.server_ca[0].cert_pem
  validity_period_hours = var.cert_validity_hours
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
}

# Creata solo quando la PKI server è interna.
resource "aws_acm_certificate" "vpn_server" {
  count = local.create_server_pki ? 1 : 0
  # private_key       = tls_private_key.server[0].private_key_pem

  # Repro ephemeral:
  # private_key = ephemeral.tls_private_key.server[0].private_key_pem

  # Repro SM:
  private_key = data.aws_secretsmanager_secret_version.server_key_external[0].secret_string

  certificate_body  = tls_locally_signed_cert.server[0].cert_pem
  certificate_chain = tls_self_signed_cert.server_ca[0].cert_pem
  tags              = merge(var.tags, { Name = "${local.name_prefix}-server-cert" })
}

# mutual-cert only
# chiave in state TF (sensitive) - aws_acm_certificate non supporta wo
# Creata solo quando la PKI client è interna.
resource "tls_private_key" "client_ca" {
  count     = local.create_client_pki ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "client_ca" {
  count           = local.create_client_pki ? 1 : 0
  private_key_pem = tls_private_key.client_ca[0].private_key_pem
  subject {
    common_name  = "${local.name_prefix}.client.ca"
    organization = local.name_prefix
  }
  validity_period_hours = var.cert_validity_hours
  is_ca_certificate     = true
  allowed_uses          = ["key_encipherment", "digital_signature", "cert_signing"]
}

resource "tls_cert_request" "client_admin" {
  count           = local.generate_client_admin_cert ? 1 : 0
  # private_key_pem = tls_private_key.client_admin[0].private_key_pem

  # Repro ephemeral:
  # private_key_pem = ephemeral.tls_private_key.client_admin.private_key_pem

  # Repro SM:
  private_key_pem = data.aws_secretsmanager_secret_version.admin_key_external[0].secret_string
  subject {
    common_name  = "${local.name_prefix}.client.admin"
    organization = local.name_prefix
  }
}

resource "tls_locally_signed_cert" "client_admin" {
  count            = local.generate_client_admin_cert ? 1 : 0
  cert_request_pem = tls_cert_request.client_admin[0].cert_request_pem
  ca_private_key_pem    = local.client_ca_private_key_pem_for_signing
  ca_cert_pem           = local.client_ca_cert_pem_for_signing
  validity_period_hours = var.cert_validity_hours
  allowed_uses          = ["key_encipherment", "digital_signature", "client_auth"]
}

# Creata solo quando la PKI client è interna.
resource "aws_acm_certificate" "client_ca" {
  count            = local.create_client_pki ? 1 : 0
  private_key      = tls_private_key.client_ca[0].private_key_pem
  certificate_body = tls_self_signed_cert.client_ca[0].cert_pem
  tags             = merge(var.tags, { Name = "${local.name_prefix}-client-ca" })
}
