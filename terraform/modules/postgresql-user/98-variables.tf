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

