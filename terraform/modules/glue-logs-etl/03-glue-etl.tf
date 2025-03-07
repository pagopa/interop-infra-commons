resource "aws_glue_job" "glue_job" {
  name     = var.glue_job_name
  role_arn = aws_iam_role.glue_role.arn

  command {
    script_location = "s3://${var.s3_script_bucket}/${var.script_key}"
    python_version  = "3"
  }

  glue_version      = var.glue_job_version
  worker_type       = var.glue_job_worker_type
  number_of_workers = var.glue_job_number_of_workers
  max_retries       = var.glue_job_max_retries
  timeout           = var.glue_job_timeout_minutes

  execution_property {
    max_concurrent_runs = var.glue_job_concurrency
  }

  default_arguments = {
    "--JOB_NAME"              = var.glue_job_name
    "--enable-auto-scaling"   = var.glue_job_enable_auto_scaling
    "--destination_s3_bucket" = var.s3_destination_bucket
    "--glue_database"         = var.glue_database_name
    "--glue_table"            = var.glue_table_name
    "--predicate"             = var.glue_job_predicate
    # TODO logging
    "--continuous-log-logGroup"          = var.cloudwatch_log_group_name
    "--enable-continuous-cloudwatch-log" = var.enable_continuous_logging
    "--continuous-log-logStreamPrefix"   = var.cloudwatch_log_stream_prefix
    "--enable-observability-metrics"     = var.enable_observability_metrics
  }

  tags = var.glue_job_tags
}