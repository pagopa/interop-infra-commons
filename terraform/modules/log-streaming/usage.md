module "log_processing" {
  source              = "./modules/log-streaming"
  stream_name         = "log-stream"
  firehose_name       = "log-firehose"
  s3_bucket_name      = "processed-logs-bucket"
  lambda_function_name = "log-parser"
}

