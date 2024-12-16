data "aws_iam_policy_document" "vpn_clients_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_policy" "vpn_clients_s3_readonly_bucket_access" {
  name = format("%s-vpn-clients-s3-access-%s", var.project_name, var.env)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:Get*",
          "s3:List*",
          "s3:Describe*",
          "s3-object-lambda:Get*",
          "s3-object-lambda:List*"
        ]
        Resource = [
          "${module.vpn_automation_bucket.s3_bucket_arn}/*",
          "${module.vpn_automation_bucket.s3_bucket_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "vpn_clients_s3_bucket_access" {
  name = format("%s-vpn-clients-s3-access-%s", var.project_name, var.env)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${module.vpn_automation_bucket.s3_bucket_arn}/*",
          "${module.vpn_automation_bucket.s3_bucket_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_policy" "vpn_clients_vpn_endpoint_access" {
  name = format("%s-vpn-clients-vpn-endpoint-access-%s", var.project_name, var.env)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeClientVpnEndpoints",
          "ec2:ExportClientVpnClientCertificateRevocationList",
          "ec2:ImportClientVpnClientCertificateRevocationList",
          "ec2:ExportClientVpnClientConfiguration"
        ]
        Resource = [
          "${var.client_vpn_endpoint_arn}"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "vpn_clients_diff_lambda" {
  assume_role_policy = data.aws_iam_policy_document.vpn_clients_assume_role.json
  name               = format("%s-vpn-clients-diff-lambda-%s", var.project_name, var.env)
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    aws_iam_policy.vpn_clients_s3_readonly_bucket_access.arn
  ]
}

resource "aws_iam_role" "vpn_clients_updater_lambda" {
  assume_role_policy = data.aws_iam_policy_document.vpn_clients_assume_role.json
  name               = format("%s-vpn-clients-updater-lambda-%s", var.project_name, var.env)
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    aws_iam_policy.vpn_clients_s3_bucket_access.arn,
    aws_iam_policy.vpn_clients_vpn_endpoint_access.arn
  ]
}

data "aws_ec2_managed_prefix_list" "s3" {
  name = "com.amazonaws.${data.aws_region.current.name}.s3"
}

resource "aws_security_group" "this_lambda" {
  name        = format("lambda/%s-vpn-automation-%s", var.project_name, var.env)
  description = format("%s SG for VPN automation lambda", var.project_name)
  vpc_id      = var.vpc_id

  egress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3.id]
  }
}

resource "aws_lambda_function" "vpn_clients_diff_lambda" {
  function_name = format("%s-vpn-clients-diff", var.project_name)
  image_uri     = format("%s:%s", aws_ecr_repository.this[format("%s-vpn-clients-updater", var.project_name)].repository_url, var.clients_updater_image_tag)
  memory_size   = 256
  package_type  = "Image"
  timeout       = 120
  role          = aws_iam_role.vpn_clients_diff_lambda.arn

  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  architectures = [
    "x86_64"
  ]
  environment {
    variables = {
      EASYRSA_BUCKET_NAME       = var.easyrsa_bucket_name                   #e.g. experimental-clientvpn
      EASYRSA_PATH              = var.easyrsa_bin_path                      #e.g. easyrsa3, bin path in EASYRSA_BUCKET_NAME
      EASYRSA_PKI_DIR           = var.easyrsa_pki_dir                       #e.g. pki-dev, pki dri path in EASYRSA_BUCKET_NAME
      LOG_LEVEL                 = var.lambda_log_level                      #e.g. debug, optional
      VPN_CLIENTS_BUCKET_NAME   = module.vpn_automation_bucket.s3_bucket_id #e.g. experimental-clientvpn
      VPN_CLIENTS_BUCKET_REGION = data.aws_region.current.name
      VPN_CLIENTS_KEY_NAME      = "vpn-clients.json"
    }
  }

  vpc_config {
    subnet_ids         = toset(var.lambda_function_subnets_ids)
    security_group_ids = [aws_security_group.this_lambda.id]
  }
}

resource "aws_lambda_function" "vpn_clients_updater_lambda" {
  function_name = format("%s-vpn-clients-updater", var.project_name)
  image_uri     = format("%s:%s", aws_ecr_repository.this[format("%s-vpn-clients-updater", var.project_name)].repository_url, var.clients_updater_image_tag)
  memory_size   = 256
  package_type  = "Image"
  timeout       = 180
  role          = aws_iam_role.vpn_clients_updater_lambda.arn

  ephemeral_storage {
    size = 512
  }
  tracing_config {
    mode = "PassThrough"
  }
  architectures = [
    "x86_64"
  ]
  environment {
    variables = {
      EASYRSA_BUCKET_NAME                  = var.easyrsa_bucket_name #e.g. experimental-clientvpn
      EASYRSA_BUCKET_REGION                = data.aws_region.current.name
      EASYRSA_PATH                         = var.easyrsa_bin_path #e.g. easyrsa3, bin path in EASYRSA_BUCKET_NAME
      EASYRSA_PKI_DIR                      = var.easyrsa_pki_dir  #e.g. pki-dev, pki dri path in EASYRSA_BUCKET_NAME
      LOG_LEVEL                            = var.lambda_log_level #e.g. debug, optional
      VPN_ENDPOINT_ID                      = var.vpn_endpoint_id
      VPN_ENDPOINT_REGION                  = data.aws_region.current.name
      VPN_SEND_MAIL_TEMPLATE_BUCKET_NAME   = module.vpn_automation_bucket.s3_bucket_id
      VPN_SEND_MAIL_TEMPLATE_BUCKET_REGION = data.aws_region.current.name
      VPN_SEND_MAIL_TEMPLATE_KEY_NAME      = "send-vpn-credentials.html"
      VPN_SES_CONFIGURATION_SET_NAME       = var.ses_configuration_set_name #e.g. internal-dev-interop-pagopa-it-config
      VPN_SES_SENDER                       = var.ses_from_address           #e.g. noreply@internal.dev.interop.pagopa.it
      VPN_SES_SENDER_NAME                  = var.ses_from_display_name      #e.g. Interop VPN
      VPN_SEND_MAIL_SUBJECT                = var.ses_mail_subject           #e.g. Interop VPN Dev access
    }
  }

  vpc_config {
    subnet_ids         = toset(var.lambda_function_subnets_ids)
    security_group_ids = [aws_security_group.this_lambda.id]
  }
}

