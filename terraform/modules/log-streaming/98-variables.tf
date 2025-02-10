variable "env" {
  type        = string
  description = "Environment name"
}

variable "module_resource_prefix" {
  type        = string
  description = "Prefix for the module resources"
}

# Metrics and alarms configuration
variable "sns_topic_name" {
  description = "Value of the sns topic name used to deliver the alarms"
  type        = string
}

variable "firehose_active_partition_count_percentage_threshold" {
  description = "Firehose active partition count percentage threshold"
  type        = number
  default     = 60
}

# Cloudwatch log group configuration for AWS Data Firehose 
variable "firehose_cloudwatch_log_group_name" {
  description = "Firehose Cloudwatch log group name"
  type        = string
}
variable "firehose_cloudwatch_log_stream_name" {
  description = "Firehose Cloudwatch log stream name"
  type        = string
}

variable "firehose_cloudwatch_log_group_retention_in_days" {
  description = "Firehose Cloudwatch log group logs retention in days"
  type        = number
  default     = 14
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

variable "firehose_buffering_size_mb" {
  type        = number
  description = "AWS Data Firehose stream buffering size in MB"
  default     = 5
}

variable "firehos_buffering_interval_seconds" {
  type        = number
  description = "AWS Data Firehose stream buffering interval in seconds"
  default     = 300
}

variable "firehose_stream_tags" {
  type        = map(string)
  description = "AWS Data Firehose stream tags"
  default     = {}
}

# AWS S3 target bucket configuration

variable "s3_bucket_name" {
  type        = string
  description = "AWS target S3 bucket name"
}

variable "s3_bucket_object_lock_enabled" {
  type = bool
  description = "Enable S3 bucket object lock"
  default = false
}

variable "s3_bucket_object_lock_mode" {
  type = string
  description = "S3 bucket object lock mode"
  default = "COMPLIANCE"

  validation {
    condition = contains(["GOVERNANCE", "COMPLIANCE"], var.s3_bucket_object_lock_mode)
    error_message = "value must be either 'GOVERNANCE' or 'COMPLIANCE'"
  }
}
variable "s3_bucket_tags" {
  type        = map(string)
  description = "AWS target S3 bucket tags"
  default     = {}
}

