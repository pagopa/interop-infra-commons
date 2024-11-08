variable "env" {
  type        = string
  description = "Environment name"
}

variable "apigw_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "apigw_single_endpoint_name" {
  description = "Name of the API Gateway"
  type        = string
}

variable "alarm_evaluation_periods" {
  description = "The number of periods over which data is compared to the specified threshold"
  type        = number
  default     = 2
}

variable "latency_threshold" {
  description = "The maximum allowed P90 latency in seconds"
  type        = number
  #default     = 10
}

variable "minimum_requests_threshold" {
  description = "The minimum number of requests expected in a 2-hour period"
  type        = number
  #default     = 720000
}

variable "error_rate_threshold" {
  description = "The maximum allowed error rate percentage"
  type        = number
  #default     = 3
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarm enters ALARM state"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "List of ARNs to notify when alarm enters OK state"
  type        = list(string)
  default     = []
}

variable "enable_single_endpoint_monitoring" {
  description = "Whether to enable monitoring for the single endpoint (/token.oauth2)"
  type        = bool
  default     = true
}

variable "api_stage" {
  description = "The stage of the API Gateway"
  type        = string
  default     = "dev"
}






