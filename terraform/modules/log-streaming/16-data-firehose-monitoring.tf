# AWS Data Fireshose Alarms - https://docs.aws.amazon.com/firehose/latest/dev/firehose-cloudwatch-metrics-best-practices.html
#
# Add CloudWatch alarms for when the following metrics exceed the buffering limit (a maximum of 15 minutes).
# - DeliveryToS3.DataFreshness
#
# Also, create alarms based on the following metric math expressions.
# - IncomingBytes
# - IncomingRecords
# - IncomingPutRequests
# - ThrottledRecords

# When dynamic partitioning on a Firehose stream is enabled, 
# there is a default quota of 500 active partitions that can be created for that Firehose stream.
# The active partition count is the total number of active partitions within the delivery buffer. 
# For example, if the dynamic partitioning query constructs 3 partitions per second and you have 
# a buffer hint configuration that triggers delivery every 60 seconds, then, on average, 
# you would have 180 active partitions. 
# Once data is delivered in a partition, then this partition is no longer active.



# Monitor active partitions - limit 500
resource "aws_cloudwatch_metric_alarm" "firehose_partition_count" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]
  
  alarm_name          = "firehose-${var.module_resource_prefix}-partitioncount-high-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "PartitionCount"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Maximum"
  threshold           = 450  # TODO quota - Warning threshold before hitting 500 limit
  alarm_description   = "Triggers when active partitions approach the AWS quota."
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}
resource "aws_cloudwatch_metric_alarm" "firehose_partition_count_percentage" {
  
  depends_on = [aws_kinesis_firehose_delivery_stream.this]
  
  alarm_name          = "firehose-${var.module_resource_prefix}-partitioncount-percentage-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = var.firehose_active_partition_count_percentage_threshold

  datapoints_to_alarm = 1
  alarm_description   = "Triggers when active partitions approach the AWS quota."
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id = "partitioncountpercentage1"
    return_data = false

    metric {
      metric_name = "PartitionCount"
      namespace   = "AWS/Firehose"
      stat        = "Sum"
      period      = 60
    }
  }

  metric_query {
    id          = "partitioncountpercentage2"
    expression  = "(partitioncountpercentage1 / 60) / 500 * 100" # TODO quota - Limit is 500 active partitions
    label       = "PartitionCountPercentage"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# DeliveryToS3.DataFreshness - Time taken to deliver data to S3 (track data freshness)
resource "aws_cloudwatch_metric_alarm" "firehose_data_freshness" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-datafreshness-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.DataFreshness"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Average"
  threshold           = 300 # Alert if data freshness exceeds 5 minutes --> buffering_interval + 60s

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

  alarm_name          = "firehose-${var.module_resource_prefix}-deliveryfailure-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 5
  metric_name         = "DeliveryToS3.Failure"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1 # Trigger alarm if more than 5 failures occur - TODO ragionare

  datapoints_to_alarm = 3
  alarm_description   = "Firehose failed to deliver data to S3"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingBytes - Total bytes sent to Firehose (Track high incoming records for unusual data volume)
resource "aws_cloudwatch_metric_alarm" "kinesis_incoming_bytes" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-incomingbytes-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IncomingBytes"
  namespace           = "AWS/Kinesis"
  period              = 300
  statistic           = "Average"
  threshold           = 50000000 # 50MB per minute threshold

  datapoints_to_alarm = 1
  alarm_description   = "High incoming data rate on Kinesis Stream"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# TODO aggiungere 30% configurabile su ActivePartitionsLimit

# IncomingBytes Utilization
resource "aws_cloudwatch_metric_alarm" "firehose_incoming_bytes_utilization" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-incomingbytes-utilization-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = 30 # Alert if usage exceeds 30% of limit - TODO configurabile , default 30% -> verificare quota

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
    expression  = "(incomingbytesutilization1 / 300) / 50000000 * 100" # Limit is 50MB/s - TODO verificare quota - altrimenti rimuovere
    label       = "IncomingBytesUtilization"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# IncomingRecords - Total records received by Firehose (Track high incoming records for unusual data volume)
#resource "aws_cloudwatch_metric_alarm" "firehose_incoming_records" {
#
#  depends_on = [aws_kinesis_firehose_delivery_stream.this]
#
#  alarm_name          = "Firehose-IncomingRecords-High"
#  comparison_operator = "GreaterThanThreshold"
#  evaluation_periods  = 1
#  metric_name         = "IncomingRecords"
#  namespace           = "AWS/Firehose"
#  period              = 300
#  statistic           = "Average"
#  threshold           = 100000 # Trigger alarm if more than 100k records per minute during 1 period (>300/s)
#
#  datapoints_to_alarm = 1
#  alarm_description   = "High volume of incoming records to Firehose"
#  alarm_actions       = [data.aws_sns_topic.this.arn]
#  dimensions = {
#    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
#  }
#}

# IncomingRecords Utilization
#resource "aws_cloudwatch_metric_alarm" "firehose_incoming_records_utilization" {
#
#  depends_on = [aws_kinesis_firehose_delivery_stream.this]
#
#  alarm_name          = "Firehose-IncomingRecords-Utilization"
#  comparison_operator = "GreaterThanThreshold"
#  evaluation_periods  = 1
#  threshold           = 30 # Alert if usage exceeds 30% of limit
#
#  datapoints_to_alarm = 1
#  alarm_description   = "Firehose is using more than 30% of its records per second limit."
#  alarm_actions       = [data.aws_sns_topic.this.arn]
#
#  metric_query {
#    id          = "incomingrecordsutilization1"
#    return_data = false
#    metric {
#      metric_name = "IncomingRecords"
#      namespace   = "AWS/Firehose"
#      stat        = "Sum"
#      period      = 300
#    }
#  }
#
#  metric_query {
#    id          = "incomingrecordsutilization2"
#    expression  = "(incomingrecordsutilization1 / 300) / 100000 * 100" # Limit is 100000 records/s
#    label       = "IncomingRecordsUtilization"
#    return_data = true
#  }
#
#  dimensions = {
#    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
#  }
#}

# ThrottledRecords 
# The number of records that were throttled because data ingestion exceeded one of the Firehose stream limits.
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-throttledrecords-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRecords"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  datapoints_to_alarm = 1
  alarm_description   = "High volume of throttled records to Firehose"
  alarm_actions       = [data.aws_sns_topic.this.arn]
  
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledDescribeStream 
# The total number of times the DescribeStream operation is throttled when the data source is a Kinesis data stream.
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-throttleddescribestream-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledDescribeStream"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  datapoints_to_alarm = 1
  alarm_description   = "High volume of throttled describe stream from Kinesis Data Stream"
  alarm_actions       = [data.aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledGetRecords
# The total number of times the GetRecords operation is throttled when the data source is a Kinesis data stream
resource "aws_cloudwatch_metric_alarm" "throttled_get_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-throttledgetrecords-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledGetRecords"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1  # Alarm if throttled GetRecords exceeds 1 occurrence

  alarm_description   = "Triggers when GetRecords API calls are throttled"
  alarm_actions       = [aws_sns_topic.this.arn]
  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledGetShardIterator
# The total number of times the GetShardIterator operation is throttled when the data source is a Kinesis data stream.
resource "aws_cloudwatch_metric_alarm" "throttled_get_shard_iterator" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-throttledgetsharditerator-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledGetShardIterator"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1  # Alarm if throttled GetShardIterator exceeds 1 occurrence

  alarm_description   = "Triggers when GetShardIterator API calls are throttled"
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}
