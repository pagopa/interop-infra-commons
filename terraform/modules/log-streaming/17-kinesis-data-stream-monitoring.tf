
# AWS Kinesis Data Stream Alarms - https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html
# AWS Kinesis Data Stream Quotas & Limits - https://docs.aws.amazon.com/streams/latest/dev/service-sizes-and-limits.html


#PutRecords.FailedRecords
#PutRecords.ThrottledRecords	
#PutRecord.Success, PutRecords.Success

# NumberOfDataStreams - Needs custom lambda to monitor it:
# Custom metric - Total number of Kinesis streams in the account/region (50 default limit)



# WriteProvisionedThroughputExceeded - Number of records rejected due to exceeding provisioned throughput
resource "aws_cloudwatch_metric_alarm" "kinesis_write_provision_exceeded" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-writeprovisionedthroughputexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "%s - Kinesis Data Stream Write Provisioning exceeded" # TODO - Aggiungere nome stream
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# ReadProvisionedThroughputExceeded - Number of records rejected due to exceeding provisioned throughput
resource "aws_cloudwatch_metric_alarm" "kinesis_write_provision_exceeded" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-readprovisionedthroughputexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Kinesis Data Stream Read Provisioning exceeded"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IteratorAgeMilliseconds - Age of the last record retrieved from the stream (latency indicator)
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-iteratorageexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Average"
  threshold           = 60000 # 1 minute delay ? Verificare
  alarm_description   = "Kinesis consumer is lagging behind in data processing"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IncomingBytes - Monitor write throughput
# data streams with the on-demand capacity mode scale up to 200 MB/s of write and 400 MB/s read throughput (not all Regions).
resource "aws_cloudwatch_metric_alarm" "kinesis_incoming_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisincomingbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IncomingBytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = data.aws_servicequotas_service_quota.kinesis_data_stream_write_quota.value * 0.3  # Warning before 200 MB/s limit - Threshold (30%)

  alarm_description   = "Triggers when incoming data rate approaches quota"
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}


# OutgoingBytes - Monitor read throughput
# data streams with the on-demand capacity mode scale up to 200 MB/s of write and 400 MB/s read throughput (not all Regions).
resource "aws_cloudwatch_metric_alarm" "kinesis_outgoing_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisoutgoingbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OutgoingBytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 320000000  # Warning before 400 MB/s limit (30%)
  alarm_description   = "Triggers when outgoing data rate approaches quota"
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}


# GetRecords.Bytes - Monitor GetRecords Transaction Size
# GetRecords can retrieve up to 10 MB of data per call from a single shard, and up to 10,000 records per call. 
# Each call to GetRecords is counted as one read transaction. 
# Each shard can support up to five read transactions per second. 
# Each read transaction can provide up to 10,000 records with an upper quota of 10 MB per transaction.
resource "aws_cloudwatch_metric_alarm" "kinesis_get_records_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisgetrecordsbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.Bytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Maximum"
  threshold           = 3000000  # Warning before 10 MB limit per call (30%) # TODO con quota
  alarm_description   = "Triggers when a single GetRecords call approaches size limit"
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}
