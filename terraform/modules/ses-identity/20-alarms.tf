resource "aws_cloudwatch_metric_alarm" "reject" {
  count = (var.create_alarms && var.sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("%s-reject-alarm", var.ses_identity_name)
  comparison_operator = "GreaterThanOrEqualToThreshold"
  metric_name         = "Reject"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "1"
  datapoints_to_alarm = "1"
  statistic           = "Sum"
  alarm_description   = "This metric checks for reject rate"
  alarm_actions       = var.sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}

resource "aws_cloudwatch_metric_alarm" "bounce" {
  count = (var.create_alarms && var.ses_reputation_sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("%s-bounce-alarm", var.ses_identity_name)
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "Reputation.BounceRate"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "0"
  datapoints_to_alarm = "1"
  statistic           = "Average"
  alarm_description   = "This metric checks for bounce rate"
  alarm_actions       = var.ses_reputation_sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}

resource "aws_cloudwatch_metric_alarm" "complaint" {
  count = (var.create_alarms && var.ses_reputation_sns_topics_arn != null) ? 1 : 0

  alarm_name          = format("%s-complaint-alarm", var.ses_identity_name)
  comparison_operator = "GreaterThanThreshold"
  metric_name         = "Reputation.ComplaintRate"
  namespace           = "AWS/SES"
  period              = "60"
  evaluation_periods  = "60"
  threshold           = "0"
  datapoints_to_alarm = "1"
  statistic           = "Average"
  alarm_description   = "This metric checks for complaint rate"
  alarm_actions       = var.ses_reputation_sns_topics_arn
  dimensions = {
    Identity = aws_sesv2_email_identity.this.email_identity
  }
}