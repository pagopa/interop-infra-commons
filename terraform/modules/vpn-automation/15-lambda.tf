locals {
  efs_mount_path            = format("/mnt/%s-vpn-automation-%s", var.project_name, var.env)
  easyrsa_pki_dir_full_path = format("%s/%s", local.efs_mount_path, var.efs_pki_directory)
}

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

resource "aws_iam_policy" "vpn_clients_s3_bucket_access" {
  name = format("%s-vpn-clients-s3-access-%s", var.project_name, var.env)
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${module.vpn_automation_bucket.s3_bucket_arn}/vpn/*",
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
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
    aws_iam_policy.vpn_clients_s3_bucket_access.arn
  ]
}

resource "aws_iam_role" "vpn_clients_updater_lambda" {
  assume_role_policy = data.aws_iam_policy_document.vpn_clients_assume_role.json
  name               = format("%s-vpn-clients-updater-lambda-%s", var.project_name, var.env)
  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaENIManagementAccess",
    "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole",
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

  ingress {
    protocol        = "tcp"
    from_port       = 2049
    to_port         = 2049
    security_groups = [aws_security_group.efs_vpn_automation.id]
  }

  egress {
    protocol        = "tcp"
    from_port       = 0
    to_port         = 65535
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.s3.id]
  }
}

resource "aws_lambda_function" "vpn_clients_diff_lambda" {
  depends_on = [aws_efs_mount_target.vpn_automation]

  function_name = format("%s-vpn-clients-diff", var.project_name)
  image_uri     = format("%s:%s", aws_ecr_repository.this[format("%s-vpn-clients-updater", var.project_name)].repository_url, var.clients_updater_image_tag)
  memory_size   = 128
  package_type  = "Image"
  timeout       = 60
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
      EASYRSA_PKI_DIR           = local.easyrsa_pki_dir_full_path
      VPN_CLIENTS_BUCKET_NAME   = module.vpn_automation_bucket.s3_bucket_id
      VPN_CLIENTS_BUCKET_REGION = data.aws_region.current.name
      VPN_CLIENTS_KEY_NAME      = "vpn/clients.json"
    }
  }

  vpc_config {
    subnet_ids         = toset(var.lambda_function_subnets_ids)
    security_group_ids = [aws_security_group.this_lambda.id]
  }

  file_system_config {
    arn              = aws_efs_file_system.vpn_automation.arn
    local_mount_path = local.efs_mount_path
  }
}

resource "aws_lambda_function" "vpn_clients_updater_lambda" {
  depends_on = [aws_efs_mount_target.vpn_automation]

  function_name = format("%s-vpn-clients-updater", var.project_name)
  image_uri     = format("%s:%s", aws_ecr_repository.this[format("%s-vpn-clients-updater", var.project_name)].repository_url, var.clients_updater_image_tag)
  memory_size   = 128
  package_type  = "Image"
  timeout       = 60
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
      EASYRSA_PKI_DIR                      = local.easyrsa_pki_dir_full_path
      VPN_ENDPOINT_ID                      = var.vpn_endpoint_id
      VPN_ENDPOINT_REGION                  = data.aws_region.current.name
      VPN_SEND_MAIL_TEMPLATE_BUCKET_NAME   = module.vpn_automation_bucket.s3_bucket_id
      VPN_SEND_MAIL_TEMPLATE_BUCKET_REGION = data.aws_region.current.name
      VPN_SEND_MAIL_TEMPLATE_KEY_NAME      = "vpn/send-vpn-credentials.html"
      VPN_SES_CONFIGURATION_SET_NAME       = var.ses_configuration_set_name
      VPN_SES_SENDER                       = var.ses_from_address
      VPN_SES_SENDER_NAME                  = var.ses_from_display_name
      VPN_SEND_MAIL_SUBJECT                = var.ses_mail_subject
    }
  }

  vpc_config {
    subnet_ids         = toset(var.lambda_function_subnets_ids)
    security_group_ids = [aws_security_group.this_lambda.id]
  }

  file_system_config {
    arn              = aws_efs_file_system.vpn_automation.arn
    local_mount_path = local.efs_mount_path
  }
}

