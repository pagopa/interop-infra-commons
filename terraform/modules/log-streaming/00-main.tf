terraform {
  required_version = "~> 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.46.0"
    }
  }
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

# SNS Target topic for Kinesis and Firehose alerts
data "aws_sns_topic" "this" {
  name = var.sns_topic_name
}
