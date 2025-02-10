# SNS Target topic for Kinesis and Firehose alerts
data "aws_sns_topic" "this" {
  name = var.sns_topic_name
}
