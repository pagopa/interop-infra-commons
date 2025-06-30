resource "aws_cloudwatch_metric_alarm" "apigw_5xx" {
  count = var.create_cloudwatch_alarm ? 1 : 0

  alarm_name        = format("%s-apigw-5xx", local.rest_apigw_name)
  alarm_description = format("%s 5xx errors", local.rest_apigw_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  metric_name = "5XXError"
  namespace   = "AWS/ApiGateway"
  dimensions = {
    ApiName = local.rest_apigw_name
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

  alarm_name        = format("%s-apigw-4xx", local.rest_apigw_name)
  alarm_description = format("%s 4xx errors", local.rest_apigw_name)

  alarm_actions = var.maintenance_mode ? [] : [var.sns_topic_arn]

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "notBreaching"

  threshold           = var.alarm_4xx_threshold_percentage
  evaluation_periods  = var.alarm_4xx_eval_periods
  datapoints_to_alarm = var.alarm_4xx_datapoints

  metric_query {
    id          = "e1"
    label       = "4xxPercentage"
    expression  = "(m1/m2)*100"
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
        ApiName = local.rest_apigw_name
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
        ApiName = local.rest_apigw_name
      }
    }
  }
}

resource "aws_cloudwatch_dashboard" "this" {
  count = var.create_cloudwatch_dashboard ? 1 : 0

  dashboard_name = replace(format("apigw-%s", local.rest_apigw_name), ".", "-")
  dashboard_body = templatefile("${path.module}/apigw-dashboard.tpl.json", {
    Region    = data.aws_region.current.name
    ApiGwName = local.rest_apigw_name
  })
}
