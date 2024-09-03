locals {
  string_equals_conditions = {
    "ses:FromAddress"     = var.allowed_from_addresses_literal
    "ses:FromDisplayName" = var.allowed_from_display_names
    "aws:SourceVpc"       = var.allowed_source_vpcs_id
  }
  string_equals_effective = { for k, v in local.string_equals_conditions : k => v if v != null }
}

resource "aws_iam_policy" "this" {
  name = var.ses_iam_policy_name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow",
      Action = [
        "ses:SendEmail",
        "ses:SendRawEmail"
      ]
      Resource = [
        var.ses_configuration_set_arn,
        var.ses_identity_arn
      ],
      Condition = merge(
        var.allowed_recipients_literal != null ? {
          "ForAllValues:StringEquals" = {
            "ses:Recipients" = var.allowed_recipients_literal
          }
        } : {},
        var.allowed_recipients_regex != null ? {
          "ForAllValues:StringLike" = {
            "ses:Recipients" = var.allowed_recipients_regex
          }
        } : {},
        # Workaround because merge does not support nested maps
        length(keys(local.string_equals_effective)) > 0 ? { "StringEquals" = local.string_equals_effective } : {}
      )
    }]
  })
}
