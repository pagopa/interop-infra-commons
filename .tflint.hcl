
plugin "terraform" {
    enabled = true
    version = "0.14.1"
    source  = "github.com/terraform-linters/tflint-ruleset-terraform"
}

plugin "aws" {
    enabled = true
    version = "0.46.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}