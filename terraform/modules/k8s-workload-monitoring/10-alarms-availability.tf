###############################################################################
# LOCALS
###############################################################################

# 

locals {
  # If other workload type need to be included, for example StatefulSet, 
  # modify as follows: (var.kind == "Deployment") -> (var.kind == "Deployment" || var.kind == "StatefulSet")
  is_pod_availability_alarm_required   = var.create_pod_availability_alarm && (var.kind == "Deployment")
  is_pod_readiness_alarm_required      = var.create_pod_readiness_alarm && (var.kind == "Deployment")
}

###############################################################################
# AVAILABILITY ALARMS
###############################################################################

# 1) Unavailable pods
resource "aws_cloudwatch_metric_alarm" "unavailable_pods" {
  count = local.is_pod_availability_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-unavailable-pods-%s", var.k8s_workload_name, var.k8s_namespace)
  alarm_description = format("Unavailable pods alarm for %s", var.k8s_workload_name)

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
        Service     = var.k8s_workload_name
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
        Service     = var.k8s_workload_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  tags = var.tags
}

# 2) Readiness pods
resource "aws_cloudwatch_metric_alarm" "readiness_pods" {
  count = local.is_pod_readiness_alarm_required ? 1 : 0

  alarm_name        = format("k8s-%s-readiness-pods-%s", var.k8s_workload_name, var.k8s_namespace)
  alarm_description = format("Readiness pods alarm for %s", var.k8s_workload_name)

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
        Service     = var.k8s_workload_name
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
        Service     = var.k8s_workload_name
        Namespace   = var.k8s_namespace
      }
    }
  }

  tags = var.tags
}
