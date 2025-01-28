variable "db_host" {
  description = "Database host"
  type        = string
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}

variable "db_name" {
  description = "Database name"
  type        = string
}

variable "db_admin_credentials_secret_arn" {
  description = "DB admin ~ username / password.."
  type        = string
}

variable "username" {
  description = "Username used to generate credentials and roles on target DB"
  type        = string
}

variable "secret_prefix" {
  description = "User secret prefix"
  type        = string
}

variable "secret_tags" {
  description = "AWS secret tags"
  type        = map(string)
  default     = {}
}

variable "enable_sql_statements" {
  description = "Enable SQL scripts execution"
  type        = bool
  default     = false
}

variable "additional_sql_statements" {
  description = "Optional SQL inline script executed after user role creation"
  type        = string
  default     = null
}