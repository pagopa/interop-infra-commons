resource "aws_kinesis_firehose_delivery_stream" "this" {

  depends_on = [
    aws_kinesis_stream.this,
    aws_s3_bucket.this,
    aws_cloudwatch_log_group.this,
    aws_cloudwatch_log_stream.this
  ]

  name        = var.firehose_stream_name
  tags        = var.firehose_stream_tags
  destination = "extended_s3"

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

    prefix              = "fh-output/namespace=!{partitionKeyFromQuery:namespace}/app=!{partitionKeyFromQuery:app}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "fh-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = format("firehose-%s-%s", var.firehose_stream_name, var.env)
      log_stream_name = "extended_s3"
    }

    dynamic_partitioning_configuration {
      enabled        = "true"
      retry_duration = 300
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }

      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      processors {
        type = "CloudWatchLogProcessing"
        parameters {
          parameter_name  = "DataMessageExtraction"
          parameter_value = "true"
        }
      }

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