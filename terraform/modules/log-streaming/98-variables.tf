variable "env" {
  type        = string
  description = "Environment name"
}

variable "datastream_stream_name" {
  type        = string
  description = "AWS Kinesis Data stream name"
}

#https://docs.aws.amazon.com/streams/latest/dev/kinesis-extended-retention.html
variable "datastream_stream_retention_period" {
  type        = string
  description = "AWS Kinesis Data stream data retention period"
  default     = 24
}

variable "datastream_tags" {
  type        = map(string)
  description = "AWS Kinesis Data stream tags"
  default     = {}
}

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

variable "s3_bucket_name" {
  type        = string
  description = "S3 target bucket name"
}

variable "s3_bucket_tags" {
  type        = map(string)
  description = "AWS target S3 bucket tags"
  default     = {}
}