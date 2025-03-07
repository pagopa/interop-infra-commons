###############################################################################
# LOCALS
###############################################################################

locals {
  is_cronjob_performance_alarm_required = var.create_cronjob_performance_alarm && var.kind == "CronJob"
  is_cronjob_app_logs_errors_alarm_required = var.create_cronjob_app_logs_errors_alarm && var.kind == "CronJob" && var.cronjob_cloudwatch_app_logs_errors_metric_name != null && var.cronjob_cloudwatch_app_logs_errors_metric_namespace != null
}

###############################################################################
# CRONJOB ALARMS
###############################################################################

# 1) Performance CPU
resource "aws_cloudwatch_metric_alarm" "cronjob_avg_cpu" {
  count = local.is_cronjob_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-avg-cpu-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("AVG CPU usage alarm for CronJob %s", var.k8s_cronjob_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_cpu_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_cronjob_name
    Namespace   = var.k8s_namespace
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  threshold           = var.cronjob_avg_cpu_alarm_threshold
  period              = var.cronjob_performance_alarms_period_seconds
  evaluation_periods  = var.cronjob_alarms_eval_periods
  datapoints_to_alarm = var.cronjob_alarms_datapoints

  tags = var.tags
}

# 2) Performance Memory
resource "aws_cloudwatch_metric_alarm" "cronjob_avg_memory" {
  count = local.is_cronjob_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-avg-memory-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("AVG memory usage alarm for CronJob %s", var.k8s_cronjob_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_memory_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_cronjob_name
    Namespace   = var.k8s_namespace
  }

  comparison_operator = "GreaterThanOrEqualToThreshold"
  statistic           = "Average"
  treat_missing_data  = "notBreaching"

  threshold           = var.cronjob_avg_memory_alarm_threshold
  period              = var.cronjob_performance_alarms_period_seconds
  evaluation_periods  = var.cronjob_alarms_eval_periods
  datapoints_to_alarm = var.cronjob_alarms_datapoints

  tags = var.tags
}

# 3) Application errors
resource "aws_cloudwatch_metric_alarm" "cronjob_app_errors" {
  count = local.is_cronjob_app_logs_errors_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-errors-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("App logs errors alarm for CronJob %s", var.k8s_cronjob_name)

  alarm_actions = var.sns_topics_arns

  metric_name = var.cronjob_cloudwatch_app_logs_errors_metric_name
  namespace   = var.cronjob_cloudwatch_app_logs_errors_metric_namespace

  dimensions = {
    PodApp       = var.k8s_cronjob_name
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