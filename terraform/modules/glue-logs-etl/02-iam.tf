resource "aws_iam_role" "glue_role" {
  name = "glue_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}


resource "aws_iam_policy" "glue_policy" {
  name        = "glue_execution_policy"
  description = "IAM policy for Glue job execution"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.source_s3_bucket}/*",
          "arn:aws:s3:::${var.destination_s3_bucket}/*"
        ]
      },
      {
        Effect   = "Allow"
        Action   = [
          "glue:GetTable",
          "glue:GetDatabase",
          "glue:GetTableVersion",
          "glue:GetTableVersions",
          "glue:CreateTable",
          "glue:UpdateTable"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "logs:CreateLogGroup"
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Effect   = "Allow"
        Action   = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:log-group:/aws-glue/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_policy_attachment" {
  role       = aws_iam_role.glue_role.name
  policy_arn = aws_iam_policy.glue_policy.arn
}
