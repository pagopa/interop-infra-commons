variable "glue_job_name" {
  description = "Name of the Glue job"
  type        = string
}
variable "glue_job_tags" {
  description = "List of Glue job tags"
  type        = map(string)
  default     = {}
}

# Glue job details
variable "glue_job_version" {
  description = "Version of Glue"
  type        = string
  default     = "4.0"
}
variable "glue_job_worker_type" {
  description = "Type of Glue worker"
  type        = string
  default     = "G.1X"
}
variable "glue_job_enable_auto_scaling" {
  description = "Enable auto scaling of the Glue job"
  type        = bool
  default     = false
}
variable "glue_job_number_of_workers" {
  description = "Number of Glue workers"
  type        = number
  default     = 1
}
variable "glue_job_max_retries" {
  description = "Max retries of the Glue job"
  type        = number
  default     = 0
}
variable "glue_job_timeout_minutes" {
  description = "Timeout of the Glue job (default 48 hours)"
  type        = number
  default     = 2880
}
variable "glue_job_concurrency" {
  description = "Max concurrent runs of the Glue job"
  type        = number
  default     = 1
}

# Glue job script
variable "s3_script_target_bucket" {
  description = "S3 bucket to store the Glue script"
  type        = string
}

variable "glue_script_tags" {
  description = "List of Glue script tags"
  type        = map(string)
  default     = {}
}

# Glue job inputs
variable "s3_destination_bucket" {
  description = "S3 destination bucket"
  type        = string
}
variable "glue_database_name" {
  description = "Name of the Glue database"
  type        = string
}
variable "glue_table_name" {
  description = "Name of the Glue table"
  type        = string
}
variable "glue_job_predicate" {
  description = "Predicate of the Glue job"
  type        = string
}

# Glue logging configuration
variable "cloudwatch_log_group_name" {
  description = "Name of the CloudWatch log group"
  type        = string
  default     = "/aws-glue/jobs/logs"
}
variable "enable_continuous_logging" {
  description = "Enable continuous logging"
  type        = string
  default     = "false"
}
variable "cloudwatch_log_stream_prefix" {
  description = "Prefix of the CloudWatch log stream"
  type        = string
  default     = ""
}
variable "enable_observability_metrics" {
  description = "Enable observability metrics"
  type        = bool
  default     = false
}