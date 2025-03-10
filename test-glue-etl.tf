module "glue-etl" {
  source = "./terraform/modules/glue-logs-etl"

  glue_job_name = "Test Glue ETL"
  s3_script_target_bucket = "experimental-clientvpn"
  s3_destination_bucket = "interop-application-logs-dev-es1-target"
  glue_database_name = "default"
  glue_table_name = "interop_application_logs_dev_es1"
  glue_job_predicate = "year == 2025 and month == 1 and day == 1"
  cloudwatch_log_group_name = "/aws-glue/jobs/logs-test"
  
}