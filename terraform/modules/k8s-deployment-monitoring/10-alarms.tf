resource "aws_cloudwatch_metric_alarm" "avg_cpu" {
  count = var.create_performance_alarm ? 1 : 0

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

resource "aws_cloudwatch_metric_alarm" "avg_memory" {
  count = var.create_performance_alarm ? 1 : 0

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

  threshold           = var.avg_cpu_alarm_threshold
  period              = var.performance_alarms_period_seconds
  evaluation_periods  = var.alarm_eval_periods
  datapoints_to_alarm = var.alarm_datapoints

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "unavailable_pods" {
  count = var.create_pod_availability_alarm ? 1 : 0

  alarm_name        = format("k8s-%s-unavailable-pods-%s", var.k8s_deployment_name, var.k8s_namespace)
  alarm_description = format("Unavailable pods alarm for %s", var.k8s_deployment_name)

  alarm_actions = var.sns_topics_arns

  comparison_operator = "GreaterThanOrEqualToThreshold"
  treat_missing_data  = "missing"
  # TODO: pass as variables?
  threshold           = 1
  datapoints_to_alarm = 1
  evaluation_periods  = 5

  metric_query {
    id          = "e1"
    label       = "Unavailable pods"
    expression  = "m1-m2"
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

resource "aws_cloudwatch_metric_alarm" "readiness_pods" {
  count = var.create_pod_readiness_alarm ? 1 : 0

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
    expression  = "m1-m2"
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

resource "aws_cloudwatch_metric_alarm" "app_errors" {
  count = var.create_app_logs_errors_alarm && var.cloudwatch_app_logs_errors_metric_name != null && var.cloudwatch_app_logs_errors_metric_namespace != null ? 1 : 0

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
