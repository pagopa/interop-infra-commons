variable "file_url" {
  description = "The url to be downloaded. The module use curl."
  nullable    = false
  type        = string

  validation {
    condition     = trimspace(var.file_url) != ""
    error_message = "file_url can't be blank"
  }
}

variable "file_sha256_hex" {
  description = "SHA256 of the resource; 64 character: digit, uppercase or lowercase letter from A to F"
  nullable    = false
  type        = string

  validation {
    condition     = can(regex("^[A-Fa-f0-9]{64}$", var.file_sha256_hex))
    error_message = "file_sha256_hex do not seem a SHA256 in hexadecimal format"
  }
}

# Validated in precondition because related to file_cache_key
variable "destination_path" {
  description = "Path where the file will be downloaded. Exclude \"file_cache_key\" use."
  type        = string
  nullable    = true
  default     = null

}

# Validated in precondition because related to file_cache_key
variable "file_cache_key" {
  description = "If specified the module download file into an internal cache. Exclude \"destination_path\" use."
  type        = string
  nullable    = true
  default     = null
}
