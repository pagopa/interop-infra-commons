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
  description = "DB admin secret ARN. Expected JSON with fields 'username', 'password'"
  type        = string
}

variable "username" {
  description = "Username to be created"
  type        = string
}

variable "generated_password_length" {
  description = "Length of the generated password for the user"
  type        = number
}

variable "generated_password_use_special_characters" {
  description = "Enable special characters in the generated password for the user"
  type        = bool
  default     = false
}

variable "secret_prefix" {
  description = "Prefix for the secret that will be created"
  type        = string
}

variable "secret_tags" {
  description = "Tags to apply to the secret that will be created"
  type        = map(string)
  default     = {}
}

variable "secret_recovery_window_in_days" {
  description = "Number of days that AWS Secrets Manager waits before it can delete the secret"
  type        = number
  default     = 0
}

variable "enable_sql_statements" {
  description = "Enable SQL scripts execution"
  type        = bool
  default     = true
}

variable "additional_sql_statements" {
  description = "Optional SQL inline script executed after user role creation/update"
  type        = string
  default     = null
}

variable "redshift_cluster" {
  description = "Use Redshift-compatible SQL scripts"
  type        = bool
  default     = false
}

variable "redshift_schema_name_procedures" {
  description = "Redshift schema name in which to create stored procedures"
  type        = string
  default     = "terraform_postgresql_user_module"
}

variable "grant_redshift_groups" {
  description = "List of groups the user must be added to. If a group does not exist, it will be created. Specifically for Redshift"
  type        = list(string)
  default     = []
}