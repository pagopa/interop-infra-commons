output "aws_region" {
  description = "The AWS region where the resources are deployed"
  value       = data.aws_region.current.name
}

output "aws_account_id" {
  description = "The AWS account ID where the resources are deployed"
  value       = data.aws_caller_identity.current.account_id
}

output "environment" {
  description = "The environment where the resources are deployed"
  value       = var.env
}

output "api_gateway_name" {
  description = "The name of the API Gateway"
  value       = var.apigw_name
}

output "api_gateway_single_endpoint_name" {
  description = "The name of the API Gateway single endpoint"
  value       = var.apigw_single_endpoint_name
}

output "api_gateway_stage" {
  description = "The stage of the API Gateway"
  value       = var.api_stage
}

output "alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold for alarms"
  value       = var.alarm_evaluation_periods
}

output "latency_threshold" {
  description = "The maximum allowed P90 latency in seconds for alarms"
  value       = var.latency_threshold
}

output "minimum_requests_threshold" {
  description = "The minimum number of requests expected in a 2-hour period for alarms"
  value       = var.minimum_requests_threshold
}

output "error_rate_threshold" {
  description = "The maximum allowed error rate percentage for alarms"
  value       = var.error_rate_threshold
}

output "alarm_actions" {
  description = "The list of ARNs to notify when an alarm enters the ALARM state"
  value       = var.alarm_actions
}

output "dashboard_names" {
  description = "The names of the CloudWatch dashboards"
  value       = [aws_cloudwatch_dashboard.apigw.dashboard_name, aws_cloudwatch_dashboard.single_endpoint[*].dashboard_name]
}

output "alarm_names" {
  description = "The names of the CloudWatch alarms"
  value = [
    aws_cloudwatch_metric_alarm.sla-p90-response-time.alarm_name,
    aws_cloudwatch_metric_alarm.sla-request-count.alarm_name,
    aws_cloudwatch_metric_alarm.sla-error-rate.alarm_name,
    aws_cloudwatch_metric_alarm.sla-endpoint-p90-response-time[*].alarm_name,
    aws_cloudwatch_metric_alarm.sla-endpoint-request-count[*].alarm_name,
    aws_cloudwatch_metric_alarm.sla-endpoint-error-rate[*].alarm_name
  ]
}