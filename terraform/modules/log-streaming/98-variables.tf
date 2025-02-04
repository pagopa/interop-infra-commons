variable "env" {
  type        = string
  description = "Environment name"
}

# Metrics and alarms configuration
variable "sns_topic_name" {
  description = "Value of the sns topic name used to deliver the alarms"
  type = "string"
}

# Cloudwatch log group configuration for AWS Data Firehose 
variable "cloudwatch_log_group_name" {
  description = "Firehose Cloudwatch log group name"
  type = string
}
variable "cloudwatch_log_stream_name" {
  description = "Firehose Cloudwatch log stream name"
  type = string
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "Firehose Cloudwatch log group logs retention in days"
  type = number
  default = 14
}

# AWS Kinesis Data Stream configuration
variable "datastream_stream_name" {
  type        = string
  description = "AWS Kinesis Data stream name"
}

variable "datastream_stream_retention_period" {
  type        = string
  description = "AWS Kinesis Data stream data retention period"
  default     = 720
}

variable "datastream_tags" {
  type        = map(string)
  description = "AWS Kinesis Data stream tags"
  default     = {}
}

# AWS Data Firehose configuration
variable "firehose_stream_name" {
  type        = string
  description = "AWS Data Firehose stream name"
  default     = "terraform-kinesis-firehose-extended-s3-test-stream"
}

variable "firehose_stream_tags" {
  type        = map(string)
  description = "AWS Data Firehose stream tags"
  default     = {}
}

# AWS S3 target bucket configuration
variable "s3_bucket_prefix" {
  type        = string
  description = "S3 target bucket name prefix"
}

variable "s3_bucket_tags" {
  type        = map(string)
  description = "AWS target S3 bucket tags"
  default     = {}
}