locals {
  ecr_arn_prefix = "arn:aws:ecr:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:repository"

  ecr_push_arns = [for repo in var.ecr_push_repositories : "${local.ecr_arn_prefix}/${repo}"]
  ecr_pull_arns = [for repo in var.ecr_pull_repositories : "${local.ecr_arn_prefix}/${repo}"]

  has_ecr        = length(var.ecr_push_repositories) > 0 || length(var.ecr_pull_repositories) > 0
  has_statements = length(var.statements) > 0
  has_policy     = local.has_ecr || local.has_statements
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    dynamic "condition" {
      for_each = var.conditions

      content {
        test     = condition.value.test
        variable = condition.value.variable
        values   = condition.value.values
      }
    }
  }
}

resource "aws_iam_role" "this" {
  name               = var.name
  description        = var.description
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "aws_iam_policy_document" "this" {
  count = local.has_policy ? 1 : 0

  dynamic "statement" {
    for_each = length(local.ecr_push_arns) > 0 ? [1] : []

    content {
      sid    = "AllowCreateRepository"
      effect = "Allow"
      actions = [
        "ecr:CreateRepository",
        "ecr:DescribeRepositories",
      ]
      resources = local.ecr_push_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.ecr_push_arns) > 0 ? [1] : []

    content {
      sid    = "AllowRepositoryLifecycle"
      effect = "Allow"
      actions = [
        "ecr:DeleteLifecyclePolicy",
        "ecr:GetLifecyclePolicy",
        "ecr:GetLifecyclePolicyPreview",
        "ecr:PutLifecyclePolicy",
        "ecr:StartLifecyclePolicyPreview",
        "ecr:TagResource",
        "ecr:UntagResource",
        "ecr:ListTagsForResource",
        "ecr:SetRepositoryPolicy",
        "ecr:GetRepositoryPolicy",
        "ecr:DeleteRepositoryPolicy",
      ]
      resources = local.ecr_push_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.ecr_push_arns) > 0 ? [1] : []

    content {
      sid    = "AllowPushPull"
      effect = "Allow"
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:DescribeImages",
        "ecr:ListImages",
      ]
      resources = local.ecr_push_arns
    }
  }

  dynamic "statement" {
    for_each = length(local.ecr_pull_arns) > 0 ? [1] : []

    content {
      sid    = "AllowPull"
      effect = "Allow"
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:DescribeImages",
        "ecr:ListImages",
      ]
      resources = local.ecr_pull_arns
    }
  }

  dynamic "statement" {
    for_each = local.has_ecr ? [1] : []

    content {
      sid       = "AllowGetAuthorizationToken"
      effect    = "Allow"
      actions   = ["ecr:GetAuthorizationToken"]
      resources = ["*"]
    }
  }

  dynamic "statement" {
    for_each = var.statements

    content {
      sid       = statement.value.sid
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources

      dynamic "condition" {
        for_each = statement.value.conditions

        content {
          test     = condition.value.test
          variable = condition.value.variable
          values   = condition.value.values
        }
      }
    }
  }
}

resource "aws_iam_role_policy" "this" {
  count = local.has_policy ? 1 : 0

  name   = var.name
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.this[0].json
}

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.managed_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}
