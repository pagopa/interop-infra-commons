resource "aws_cloudwatch_log_group" "firehose" {# TODO verificare formato se usato da firehose
  name              = var.firehose_cloudwatch_log_group_name
  retention_in_days = var.firehose_cloudwatch_log_group_retention_in_days
}

resource "aws_cloudwatch_log_stream" "firehose" {
  name           = var.firehose_cloudwatch_log_stream_name
  log_group_name = aws_cloudwatch_log_group.firehose.name
}
