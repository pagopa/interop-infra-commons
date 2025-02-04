resource "aws_kinesis_stream" "this" {
  name             = var.datastream_stream_name
  retention_period = var.datastream_stream_retention_period
  encryption_type  = "KMS"

  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = var.datastream_tags
}


# TODO verificare se gestire log group

# TODO allarmi per eventuali errori su kinesis data stream e firehose (allarme sul 30%)