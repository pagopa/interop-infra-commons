variable "env" {
  type        = string
  description = "Environment name"
}

variable "stream_name" {
  type        = string
  description = "Log stream name"
}

variable "firehose_name" {
  type        = string
  description = "Firehose stream name"
}

variable "s3_bucket_name" {
  type        = string
  description = "S3 target bucket name"
}
