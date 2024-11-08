# General API Gateway Alarms
resource "aws_cloudwatch_metric_alarm" "p90_latency" {
  alarm_name          = "${var.env}-${var.apigw_name}-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.latency_threshold * 1000 # Convert seconds to milliseconds
  alarm_description   = "P90 API Gateway latency is too high"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "m1/1000"
    label       = "P90 Response Time (s)"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "Latency"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "p90"

      dimensions = {
        ApiName = var.apigw_name
      }
    }
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}

resource "aws_cloudwatch_metric_alarm" "request_count" {
  alarm_name          = "${var.env}-${var.apigw_name}-low-requests"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "7200" # 120 minutes
  statistic           = "Sum"
  threshold           = var.minimum_requests_threshold
  alarm_description   = "API Gateway request count is too low"
  treat_missing_data  = "breaching"

  dimensions = {
    ApiName = var.apigw_name
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}

resource "aws_cloudwatch_metric_alarm" "error_rate" {
  alarm_name          = "${var.env}-${var.apigw_name}-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.error_rate_threshold
  alarm_description   = "API Gateway 5XX error rate is too high"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Sum"

      dimensions = {
        ApiName = var.apigw_name
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Sum"

      dimensions = {
        ApiName = var.apigw_name
      }
    }
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}

# Single Endpoint Alarms
resource "aws_cloudwatch_metric_alarm" "endpoint_p90_latency" {
  count               = var.enable_single_endpoint_monitoring ? 1 : 0
  alarm_name          = "${var.env}-${var.apigw_single_endpoint_name}-token-high-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.latency_threshold * 1000 # Convert seconds to milliseconds
  alarm_description   = "P90 API Gateway endpoint latency is too high"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "m1/1000"
    label       = "P90 Response Time (s)"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "Latency"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "p90"

      dimensions = {
        ApiName  = var.apigw_single_endpoint_name
        Resource = "/token.oauth2"
        Stage    = var.api_stage
        Method   = "POST"
      }
    }
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}

resource "aws_cloudwatch_metric_alarm" "endpoint_request_count" {
  count               = var.enable_single_endpoint_monitoring ? 1 : 0
  alarm_name          = "${var.env}-${var.apigw_single_endpoint_name}-token-low-requests"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  metric_name         = "Count"
  namespace           = "AWS/ApiGateway"
  period              = "7200" # 120 minutes
  statistic           = "Sum"
  threshold           = var.minimum_requests_threshold
  alarm_description   = "API Gateway endpoint request count is too low"
  treat_missing_data  = "breaching"

  dimensions = {
    ApiName  = var.apigw_single_endpoint_name
    Resource = "/token.oauth2"
    Stage    = var.api_stage
    Method   = "POST"
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}

resource "aws_cloudwatch_metric_alarm" "endpoint_error_rate" {
  count               = var.enable_single_endpoint_monitoring ? 1 : 0
  alarm_name          = "${var.env}-${var.apigw_single_endpoint_name}-token-high-error-rate"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.alarm_evaluation_periods
  threshold           = var.error_rate_threshold
  alarm_description   = "API Gateway endpoint 5XX error rate is too high"
  treat_missing_data  = "notBreaching"

  metric_query {
    id          = "e1"
    expression  = "m2/m1*100"
    label       = "Error Rate"
    return_data = "true"
  }

  metric_query {
    id = "m1"

    metric {
      metric_name = "Count"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Sum"

      dimensions = {
        ApiName  = var.apigw_single_endpoint_name
        Resource = "/token.oauth2"
        Stage    = var.api_stage
        Method   = "POST"
      }
    }
  }

  metric_query {
    id = "m2"

    metric {
      metric_name = "5XXError"
      namespace   = "AWS/ApiGateway"
      period      = "60"
      stat        = "Sum"

      dimensions = {
        ApiName  = var.apigw_single_endpoint_name
        Resource = "/token.oauth2"
        Stage    = var.api_stage
        Method   = "POST"
      }
    }
  }

  alarm_actions = var.alarm_actions
  ok_actions    = var.ok_actions
}