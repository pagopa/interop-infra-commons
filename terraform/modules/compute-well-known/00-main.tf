terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.100"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.4"
    }
  }
}
