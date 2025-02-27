###############################################################################
# LOCALS
###############################################################################

locals {
  is_app_logs_errors_alarm_required = var.create_app_logs_errors_alarm && var.cloudwatch_app_logs_errors_metric_name != null && var.cloudwatch_app_logs_errors_metric_namespace != null
}

###############################################################################
# COMMON ALARMS
###############################################################################

# 1) Performance CPU
resource "aws_cloudwatch_metric_alarm" "avg_cpu" {
  count = var.create_performance_alarm ? 1 : 0

  alarm_name        = format("k8s-%s-avg-cpu-%s", var.k8s_workload_name, var.k8s_namespace)
  alarm_description = format("AVG CPU usage alarm for %s", var.k8s_workload_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_cpu_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_workload_name
    Namespace   = var.k8s_namespace
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  threshold           = var.avg_cpu_alarm_threshold
  period              = var.performance_alarms_period_seconds
  evaluation_periods  = var.alarm_eval_periods
  datapoints_to_alarm = var.alarm_datapoints

  tags = var.tags
}

# 2) Performance Memory
resource "aws_cloudwatch_metric_alarm" "avg_memory" {
  count = var.create_performance_alarm ? 1 : 0

  alarm_name        = format("k8s-%s-avg-memory-%s", var.k8s_workload_name, var.k8s_namespace)
  alarm_description = format("AVG memory usage alarm for %s", var.k8s_workload_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_memory_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_workload_name
    Namespace   = var.k8s_namespace
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  threshold           = var.avg_memory_alarm_threshold
  period              = var.performance_alarms_period_seconds
  evaluation_periods  = var.alarm_eval_periods
  datapoints_to_alarm = var.alarm_datapoints

  tags = var.tags
}

# 3) Application errors
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  count = local.is_app_logs_errors_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-errors-%s", var.k8s_workload_name, var.k8s_namespace)
  alarm_description = format("Application errors alarm for %s",  var.k8s_workload_name)

  alarm_actions = var.sns_topics_arns

  metric_name = var.cloudwatch_app_logs_errors_metric_name
  namespace   = var.cloudwatch_app_logs_errors_metric_namespace

  dimensions = {
    PodApp       = var.k8s_workload_name
    PodNamespace = var.k8s_namespace
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Sum"
  treat_missing_data  = "notBreaching"

  threshold           = 1
  period              = 60 # 1 minute
  evaluation_periods  = 5
  datapoints_to_alarm = 1

  tags = var.tags
}