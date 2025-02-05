# AWS Data Fireshose Alarms - https://docs.aws.amazon.com/firehose/latest/dev/firehose-cloudwatch-metrics-best-practices.html
#
# Add CloudWatch alarms for when the following metrics exceed the buffering limit (a maximum of 15 minutes).
# - DeliveryToS3.DataFreshness
#
# Also, create alarms based on the following metric math expressions.
# - IncomingBytes (Sum per 5 Minutes) / 300 approaches a percentage of BytesPerSecondLimit.
# - IncomingRecords (Sum per 5 Minutes) / 300 approaches a percentage of RecordsPerSecondLimit.
# - IncomingPutRequests (Sum per 5 Minutes) / 300 approaches a percentage of PutRequestsPerSecondLimit.
#
# Another metric for which we recommend an alarm is ThrottledRecords.
# - ThrottledRecords (Sum per 5 Minutes) / 300 approaches a percentage of ThrottledRecordsPerSecondLimit.

resource "aws_cloudwatch_metric_alarm" "firehose_data_freshness" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-DataFreshness"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.DataFreshness"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Average"
  threshold           = 300 # Alert if data freshness exceeds 5 minutes

  datapoints_to_alarm = 1
  alarm_description   = "Firehose Data is getting delayed in delivery to S3"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# DeliveryToS3.Failure - Number of records that failed to be delivered (track problems in data delivery to S3 bucket)
resource "aws_cloudwatch_metric_alarm" "firehose_delivery_failure" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-DeliveryFailure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.Failure"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 5 # Trigger alarm if more than 5 failures occur

  datapoints_to_alarm = 1
  alarm_description   = "Firehose failed to deliver data to S3"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingBytes - Total bytes sent to Firehose (Track high incoming records for unusual data volume)
resource "aws_cloudwatch_metric_alarm" "kinesis_incoming_bytes" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Kinesis-IncomingBytes-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "IncomingBytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Average"
  threshold           = 50000000 # 50MB per minute threshold

  datapoints_to_alarm = 2
  alarm_description   = "High incoming data rate on Kinesis Stream"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingBytes Utilization
resource "aws_cloudwatch_metric_alarm" "firehose_incoming_bytes_utilization" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-IncomingBytes-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 30 # Alert if usage exceeds 30% of limit

  datapoints_to_alarm = 1
  alarm_description   = "Firehose is using more than 30% of its bytes per second limit."
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id = "incomingbytesutilization1"
    return_data = false

    metric {
      metric_name = "IncomingBytes"
      namespace   = "AWS/Firehose"
      stat        = "Sum"
      period      = 300 # 5 minutes
    }
  }

  metric_query {
    id          = "incomingbytesutilization2"
    expression  = "(incomingbytesutilization1 / 300) / 50000000 * 100" # Limit is 50MB/s
    label       = "IncomingBytesUtilization"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingRecords - Total records received by Firehose (Track high incoming records for unusual data volume)
resource "aws_cloudwatch_metric_alarm" "firehose_incoming_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-IncomingRecords-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "IncomingRecords"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Average"
  threshold           = 100000 # Trigger alarm if more than 100k records per minute during 2 periods

  datapoints_to_alarm = 2
  alarm_description   = "High volume of incoming records to Firehose"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingRecords Utilization
resource "aws_cloudwatch_metric_alarm" "firehose_incoming_records_utilization" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-IncomingRecords-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 30 # Alert if usage exceeds 30% of limit

  datapoints_to_alarm = 1
  alarm_description   = "Firehose is using more than 30% of its records per second limit."
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id          = "incomingrecordsutilization1"
    return_data = false
    metric {
      metric_name = "IncomingRecords"
      namespace   = "AWS/Firehose"
      stat        = "Sum"
      period      = 300
    }
  }

  metric_query {
    id          = "incomingrecordsutilization2"
    expression  = "(incomingrecordsutilization1 / 300) / 10000 * 100" # Limit is 10000 records/sec
    label       = "IncomingRecordsUtilization"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingPutRequests Utilization
resource "aws_cloudwatch_metric_alarm" "firehose_incoming_put_requests_utilization" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "Firehose-IncomingPutRequests-Utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 30 # Alert if usage exceeds 30% of limit

  datapoints_to_alarm = 1
  alarm_description   = "Firehose is using more than 30% of its put requests per second limit."
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id          = "incomingputrequestsutilization1"
    return_data = false
    metric {
      metric_name = "IncomingRecords"
      namespace   = "AWS/Firehose"
      stat        = "Sum"
      period      = 300
    }
  }

  metric_query {
    id          = "m1"
    metric_name = "IncomingPutRequests"
    namespace   = "AWS/Firehose"
    period      = 300
    stat        = "Sum"
    return_data = false
  }

  metric_query {
    id          = "m2"
    expression  = "(m1 / 300) / 500 * 100" # Assuming limit is 500 put requests/sec
    label       = "IncomingPutRequestsUtilization"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# 🔹 CloudWatch Alarm for Firehose - ThrottledRecords
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_records" {
  alarm_name          = "Firehose-ThrottledRecords"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 10 # Alert if more than 10 records are throttled
  alarm_description   = "Firehose is throttling incoming records."
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id          = "m1"
    metric_name = "ThrottledRecords"
    namespace   = "AWS/Firehose"
    period      = 300
    stat        = "Sum"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = "your-firehose-stream-name"
  }
}