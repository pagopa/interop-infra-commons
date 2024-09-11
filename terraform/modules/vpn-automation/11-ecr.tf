locals {
  repository_names = [
    format("%s-vpn-clients-diff", var.project_name),
    format("%s-vpn-clients-updater", var.project_name)
  ]
}

resource "aws_ecr_repository" "this" {
  for_each = toset(local.repository_names)

  image_tag_mutability = var.env == "test" || var.env == "prod" ? "IMMUTABLE" : "MUTABLE"
  name                 = each.key
}

resource "aws_ecr_lifecycle_policy" "this" {
  for_each = { for repo in aws_ecr_repository.this : repo.name => repo if var.env == "dev" }

  repository = each.value.name
  policy     = <<EOF
  {
    "rules": [
      {
        "rulePriority": 1,
        "description": "Delete untagged images",
        "selection": {
          "tagStatus": "untagged",
          "countType": "sinceImagePushed",
          "countUnit": "days",
          "countNumber": 1
        },
        "action": {
          "type": "expire"
        }
      }
    ]
  }
  EOF
}

data "aws_iam_policy_document" "lambda_ecr_image_retrieval_policy" {
  statement {
    sid    = "LambdaECRImageRetrievalPolicy"
    effect = "Allow"

    actions = [
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer"
    ]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "aws:sourceARN"
      values = [
        aws_lambda_function.vpn_clients_diff_lambda.arn,
        aws_lambda_function.vpn_clients_updater_lambda.arn
      ]
    }
  }
}

resource "aws_ecr_repository_policy" "vpn_clients_ecr_retrieval" {
  for_each = toset(local.repository_names)

  repository = aws_ecr_repository.this[each.key].name
  policy     = data.aws_iam_policy_document.lambda_ecr_image_retrieval_policy.json
}