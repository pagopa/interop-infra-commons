variable "aws_region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "tags" {
  type        = map(any)
  description = "Tags applied to all resources that support them"
  default = {
    "CreatedBy" : "Terraform",
  }
}
