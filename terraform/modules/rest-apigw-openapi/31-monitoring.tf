resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  count = var.create_cloudwatch_alarm ? 1 : 0

  alarm_name        = format("%s-apigw-5xx", var.rest_apigw_name)
  alarm_description = format("%s 5xx errors", var.rest_apigw_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  metric_name = "5XXError"
  namespace   = "AWS/ApiGateway"
  dimensions = {
    ApiName = var.rest_apigw_name
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = var.alarm_5xx_threshold
  period              = var.alarm_5xx_period
  evaluation_periods  = var.alarm_5xx_eval_periods
  datapoints_to_alarm = var.alarm_5xx_datapoints
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx" {
  count = var.create_cloudwatch_alarm_4xx ? 1 : 0

  alarm_name        = format("%s-apigw-4xx", var.rest_apigw_name)
  alarm_description = format("%s 4xx errors", var.rest_apigw_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  threshold           = var.alarm_4xx_threshold_percentage
  evaluation_periods  = var.alarm_4xx_eval_periods
  datapoints_to_alarm = var.alarm_4xx_datapoints

  metric_query {
    id          = "e1"
    label       = "4xxPercentage"
    expression  = "IF( m2 == 0 OR m2 < ${var.alarm_4xx_min_requests}, 0, (m1/m2) ) * 100"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Count4xx"
    return_data = false

    metric {
      stat        = "Sum"
      period      = var.alarm_4xx_period
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName = var.rest_apigw_name
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "PostTokenCount"
    return_data = false

    metric {
      stat        = "Sum"
      period      = var.alarm_4xx_period
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName = var.rest_apigw_name
      }
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "apigw_4xx_low_requests" {
  count = var.additional_4xx_alarm_config != null ? 1 : 0

  alarm_name        = format("%s-apigw-4xx-low-requests", var.rest_apigw_name)
  alarm_description = format("%s 4xx errors low requests", var.rest_apigw_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  threshold           = var.additional_4xx_alarm_config.threshold_percentage
  evaluation_periods  = var.additional_4xx_alarm_config.eval_periods
  datapoints_to_alarm = var.additional_4xx_alarm_config.datapoints

  metric_query {
    id          = "e1"
    label       = "4xxPercentage"
    expression  = "IF( m2 == 0 OR m2 < ${var.additional_4xx_alarm_config.min_requests}, 0, (m1/m2) ) * 100"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Count4xx"
    return_data = false

    metric {
      stat        = "Sum"
      period      = var.alarm_4xx_period
      metric_name = "4XXError"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName = var.rest_apigw_name
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "PostTokenCount"
    return_data = false

    metric {
      stat        = "Sum"
      period      = var.alarm_4xx_period
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"

      dimensions = {
        ApiName = var.rest_apigw_name
      }
    }
  }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_cloudwatch_dashboard ? 1 : 0

  dashboard_name = replace(format("apigw-%s", var.rest_apigw_name), ".", "-")
  dashboard_body = templatefile("${path.module}/apigw-dashboard.tpl.json", {
    Region    = data.aws_region.current.name
    ApiGwName = var.rest_apigw_name
  })
}

resource "aws_cloudwatch_query_definition" "apigw_5xx" {
  count = var.create_cloudwatch_queries && var.web_acl_arn != null && data.aws_cloudwatch_log_group.this.arn != null ? 1 : 0
  
  name = "APIGW-${title(var.rest_apigw_name)}-5xx"

  log_group_names = [data.aws_cloudwatch_log_group.this.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${aws_api_gateway_rest_api.this.id}"
    | filter status like /5./
    | sort @timestamp desc
  EOT
}

resource "aws_cloudwatch_query_definition" "apigw_waf_block" {
  count = var.create_cloudwatch_queries && var.web_acl_arn != null && data.aws_cloudwatch_log_group.this.arn != null ? 1 : 0

  name = "APIGW-${title(var.rest_apigw_name)}-WAF-Block"

  log_group_names = [data.aws_cloudwatch_log_group.this.name]

  query_string = <<-EOT
    fields @timestamp, @message
    | filter apigwId = "${aws_api_gateway_rest_api.this.id}"
    | filter wafStatus != "200"
    | sort @timestamp desc
  EOT
}