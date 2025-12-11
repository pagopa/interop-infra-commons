variable "env" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Requested domain name"
  type        = string
}

variable "hosted_zone_id" {
  description = "ID of the hosted zone for the requested domain name"
  type        = string
}
