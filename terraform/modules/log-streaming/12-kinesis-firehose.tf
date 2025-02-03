data "aws_iam_policy_document" "firehose_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = format("log_stream_firehose_role_%s", var.env)
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

# IAM Policy for Firehose
resource "aws_iam_policy" "firehose_policy" {
  name        = format("log_stream_firehose_policy_%s", var.env)
  description = "Policy to allow Firehose to read from Kinesis Data Stream and write to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ],
        Resource = aws_kinesis_stream.this.arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:PutObject",
          "s3:GetBucketLocation"
        ],
        Resource = [
          aws_s3_bucket.this.arn,
          format("%s/*", aws_s3_bucket.this.arn)
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents",
          "logs:CreateLogStream"
        ],
        Resource = format("%s/*", aws_kinesis_firehose_delivery_stream.this.arn)
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}

resource "aws_kinesis_firehose_delivery_stream" "this" {

  depends_on = [
    aws_kinesis_stream.this,
    aws_s3_bucket.this
  ]

  name        = var.firehose_stream_name
  destination = "extended_s3"
  tags        = var.firehose_stream_tags

  server_side_encryption {
    enabled = true
  }
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.this.arn

    buffering_size     = 64
    buffering_interval = 300
    compression_format = "GZIP"
    custom_time_zone   = "UTC"

    # Example prefix using partitionKeyFromQuery, applicable to JQ processor
    prefix              = "fh-output/namespace=!{partitionKeyFromQuery:namespace}/app=!{partitionKeyFromQuery:app}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "fh-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = format("firehose-%s-%s", var.firehose_stream_name, var.env)
      log_stream_name = "extended_s3"
    }

    # https://docs.aws.amazon.com/firehose/latest/dev/dynamic-partitioning.html
    dynamic_partitioning_configuration {
      enabled        = "true"
      retry_duration = 300
    }

    processing_configuration {
      enabled = "true"

      # Multi-record deaggregation processor example
      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      # New line delimiter processor example
      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{namespace:.pod_namespace,app:.pod_app}"
        }
      }
    }
  }
}