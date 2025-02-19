################################################################################
# KIND: Deployment or CronJob
################################################################################
variable "kind" {
  type        = string
  description = "Kubernetes workload type: 'Deployment' or 'CronJob'"
}

################################################################################
# COMMON VARIABLES
################################################################################
variable "tags" {
  type = map(any)
  default = {
    CreatedBy = "Terraform"
  }
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "k8s_namespace" {
  description = "Namespace of the K8s deployment"
  type        = string
}

################################################################################
# SNS
################################################################################
variable "sns_topics_arns" {
  description = "ARNs of the SNS topics for alarms notifications"
  type        = list(string)
  default     = []
}


################################################################################
# WORKLOAD
################################################################################
variable "k8s_workload_name" {
  description = "Name of the K8s deployment"
  type        = string
}

################################################################################
# WORKLOAD
################################################################################
variable "create_pod_availability_alarm" {
  description = "If set to true, creates the unavailable_pods alarm"
  type        = bool
  default     = false
}

variable "create_pod_readiness_alarm" {
  description = "If set to true, creates the readiness_pods alarm"
  type        = bool
  default     = false
}

variable "create_performance_alarm" {
  description = "If set to true, creates the avg_cpu and avg_memory alarms"
  type        = bool
  default     = false
}

variable "avg_cpu_alarm_threshold" {
  description = "Threshold to trigger the AVG cpu alarm"
  type        = number
  default     = null
}

variable "avg_memory_alarm_threshold" {
  description = "Threshold to trigger the AVG memory alarm"
  type        = number
  default     = null
}

variable "performance_alarms_period_seconds" {
  description = "Period (in seconds) over which the alarm statistic is applied for performance alarms"
  type        = number
  default     = null
}

variable "alarm_eval_periods" {
  description = "Number of periods to evaluate for the alarms"
  type        = number
  default     = 1
}

variable "alarm_datapoints" {
  description = "Number of breaching datapoints in the evaluation period to trigger the alarms"
  type        = number
  default     = 1
}

variable "create_app_logs_errors_alarm" {
  description = "If set to true, creates the app_errors alarms"
  type        = bool
  default     = false
}

variable "cloudwatch_app_logs_errors_metric_name" {
  description = "Name of the app logs metric in CloudWatch"
  type        = string
  default     = null
}

variable "cloudwatch_app_logs_errors_metric_namespace" {
  description = "Namespace of the app logs metric in CloudWatch"
  type        = string
  default     = null
}

################################################################################
# CRONJOB
################################################################################

# variable "create_cronjob_performance_alarm" {
#   description = "If set to true, creates the avg_cpu and avg_memory alarms (CronJob)"
#   type        = bool
#   default     = false
# }

# variable "cronjob_avg_cpu_alarm_threshold" {
#   description = "Threshold to trigger the AVG cpu alarm (CronJob)"
#   type        = number
#   default     = null
# }

# variable "cronjob_avg_memory_alarm_threshold" {
#   description = "Threshold to trigger the AVG memory alarm (CronJob)"
#   type        = number
#   default     = null
# }

# variable "cronjob_performance_alarms_period_seconds" {
#   description = "Period (in seconds) over which the alarm statistic is applied for performance alarms (CronJob)."
#   type        = number
#   default     = 60
# }

# variable "cronjob_alarms_eval_periods" {
#   description = "Number of periods to evaluate for the alarms (CronJob)"
#   type        = number
#   default     = 1
# }

# variable "cronjob_alarms_datapoints" {
#   description = "Number of breaching datapoints in the evaluation period to trigger the alarms (CronJob)."
#   type        = number
#   default     = 1
# }

# variable "create_cronjob_app_logs_errors_alarm" {
#   description = "If set to true, creates the app_errors alarms (CronJob)"
#   type        = bool
#   default     = false
# }

# variable "cronjob_cloudwatch_app_logs_errors_metric_name" {
#   description = "Name of the app logs metric in CloudWatch (CronJob)."
#   type        = string
#   default     = null
# }

# variable "cronjob_cloudwatch_app_logs_errors_metric_namespace" {
#   description = "Namespace of the app logs metric in CloudWatch (CronJob)."
#   type        = string
#   default     = null
# }

################################################################################
# DASHBOARD
################################################################################
variable "create_dashboard" {
  description = "If set to true, creates the dashboard (if kind = Deployment)."
  type        = bool
  default     = false
}

variable "number_of_digits" {
  description = "Number of digits after the comma"
  type        = number
  default     = 0
}