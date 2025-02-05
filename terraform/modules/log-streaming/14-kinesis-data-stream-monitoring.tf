
# AWS Kinesis Data Stream Alarms
# IncomingBytes	Total incoming data in bytes
# IncomingRecords	Total number of records written
# ReadProvisionedThroughputExceeded	Number of records rejected due to exceeding read limits
# GetRecords.Bytes	Number of bytes retrieved via GetRecords

# WriteProvisionedThroughputExceeded - Number of records rejected due to exceeding provisioned throughput
resource "aws_cloudwatch_metric_alarm" "kinesis_write_provision_exceeded" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "Kinesis-WriteProvisionExceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Kinesis Data Stream Write Provisioning exceeded"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IteratorAgeMilliseconds - Age of the last record retrieved from the stream (latency indicator)
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "Kinesis-IteratorAgeExceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Average"
  threshold           = 300000 # 5 minutes delay
  alarm_description   = "Kinesis consumer is lagging behind in data processing"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}