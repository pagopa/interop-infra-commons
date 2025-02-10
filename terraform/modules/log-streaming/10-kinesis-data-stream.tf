resource "aws_kinesis_stream" "this" {
  name             = var.datastream_stream_name
  retention_period = var.datastream_stream_retention_period
  encryption_type  = "KMS"
  
  # shard count is managed dynamically since stream mode is ON DEMAND
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = var.datastream_tags
}