variable "env" {
  type        = string
  description = "Environment name"
}

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

variable "k8s_deployment_name" {
  description = "Name of the K8s deployment"
  type        = string
}

variable "sns_topics_arns" {
  description = "ARNs of the SNS topics for alarms notifications"
  type        = list(string)
  default     = []
}

variable "create_pod_availability_alarm" {
  description = "If set to true, creates the unavailable_pods alarm"
  type        = bool
}

variable "create_pod_readiness_alarm" {
  description = "If set to true, creates the readiness_pods alarm"
  type        = bool
}

variable "create_performance_alarm" {
  description = "If set to true, creates the avg_cpu and avg_memory alarms"
  type        = bool
}

variable "create_app_logs_errors_alarm" {
  description = "If set to true, creates the app_errors alarms"
  type        = bool
}

variable "create_dashboard" {
  description = "If set to true, creates the dashboard"
  type        = bool
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

variable "number_of_digits" {
  description = "Number of digits after the comma"
  type        = number
  default     = 0
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
