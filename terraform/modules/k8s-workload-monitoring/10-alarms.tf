###############################################################################
# LOCALS
###############################################################################
locals {
  # ====== Deployment  ======
  is_performance_alarm_required        = var.create_performance_alarm && var.kind == "Deployment"
  is_pod_availability_alarm_required   = var.create_pod_availability_alarm && var.kind == "Deployment"
  is_pod_readiness_alarm_required      = var.create_pod_readiness_alarm && var.kind == "Deployment"
  is_app_logs_errors_alarm_required    = var.create_app_logs_errors_alarm && var.kind == "Deployment" && var.cloudwatch_app_logs_errors_metric_name != null && var.cloudwatch_app_logs_errors_metric_namespace != null

  # ====== CronJob  ======
  is_cronjob_performance_alarm_required = var.create_cronjob_performance_alarm && var.kind == "CronJob"
  is_cronjob_app_logs_errors_alarm_required = var.create_cronjob_app_logs_errors_alarm && var.kind == "CronJob" && var.cronjob_cloudwatch_app_logs_errors_metric_name != null && var.cronjob_cloudwatch_app_logs_errors_metric_namespace != null
}

###############################################################################
# DEPLOYMENT ALARMS
###############################################################################

# 1) AVG CPU (Deployment)
resource "aws_cloudwatch_metric_alarm" "avg_cpu" {
  count = local.is_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-avg-cpu-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("AVG CPU usage alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_cpu_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_deployment_name
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

# 2) AVG MEMORY (Deployment)
resource "aws_cloudwatch_metric_alarm" "avg_memory" {
  count = local.is_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-avg-memory-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("AVG memory usage alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  metric_name = "pod_memory_utilization_over_pod_limit"
  namespace   = "ContainerInsights"
  dimensions = {
    ClusterName = var.eks_cluster_name
    Service     = var.k8s_deployment_name
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

# 3) Unavailable pods (Deployment)
resource "aws_cloudwatch_metric_alarm" "unavailable_pods" {
  count = local.is_pod_availability_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-unavailable-pods-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("Unavailable pods alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  threshold           = 1
  datapoints_to_alarm = 1
  evaluation_periods  = 5

  metric_query {
    id          = "e1"
    label       = "Unavailable pods"
    expression  = "m1 - m2"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Total replicas"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "kube_deployment_status_replicas"
      namespace   = "ContainerInsights"
      
      dimensions = {
        ClusterName = var.eks_cluster_name
        Service     = var.k8s_deployment_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "Available replicas"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "kube_deployment_status_replicas_available"
      namespace   = "ContainerInsights"

      dimensions = {
        ClusterName = var.eks_cluster_name
        Service     = var.k8s_deployment_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  tags = var.tags
}

# 4) Readiness pods (Deployment)
resource "aws_cloudwatch_metric_alarm" "readiness_pods" {
  count = local.is_pod_readiness_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-readiness-pods-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("Readiness pods alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"
    # TODO: pass as variables?
  threshold           = 1
  datapoints_to_alarm = 1
  evaluation_periods  = 5

  metric_query {
    id          = "e1"
    label       = "Not ready pods"
    expression  = "m1 - m2"
    return_data = true
  }

  metric_query {
    id          = "m1"
    label       = "Desired replicas"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "kube_deployment_spec_replicas"
      namespace   = "ContainerInsights"

      dimensions = {
        ClusterName = var.eks_cluster_name
        Service     = var.k8s_deployment_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  metric_query {
    id          = "m2"
    label       = "Ready replicas"
    return_data = false

    metric {
      stat   = "Maximum"
      period = 60 # 1 minute

      metric_name = "kube_deployment_status_replicas_ready"
      namespace   = "ContainerInsights"

      dimensions = {
        ClusterName = var.eks_cluster_name
        Service     = var.k8s_deployment_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  tags = var.tags
}

# 5) Application errors (Deployment)
resource "aws_cloudwatch_metric_alarm" "app_errors" {
  count = local.is_app_logs_errors_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-errors-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("Application errors alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  metric_name = var.cloudwatch_app_logs_errors_metric_name
  namespace   = var.cloudwatch_app_logs_errors_metric_namespace

  dimensions = {
    PodApp       = var.k8s_deployment_name
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

###############################################################################
# CRONJOB ALARMS
###############################################################################

# 1) Performance CPU (CronJob)
resource "aws_cloudwatch_metric_alarm" "cronjob_avg_cpu" {
  count = local.is_cronjob_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-avg-cpu-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("AVG CPU usage alarm for CronJob %s in %s", var.k8s_cronjob_name, var.k8s_namespace)

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

# 2) Performance Memory (CronJob)
resource "aws_cloudwatch_metric_alarm" "cronjob_avg_memory" {
  count = local.is_cronjob_performance_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-avg-memory-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("AVG memory usage alarm for CronJob %s in %s", var.k8s_cronjob_name, var.k8s_namespace)

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

# 3) Application errors (CronJob)
resource "aws_cloudwatch_metric_alarm" "cronjob_app_errors" {
  count = local.is_cronjob_app_logs_errors_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-cronjob-errors-%s", var.k8s_cronjob_name, var.k8s_namespace)
  alarm_description = format("App logs errors alarm for CronJob %s in %s", var.k8s_cronjob_name, var.k8s_namespace)

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