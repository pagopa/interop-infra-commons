data "aws_cloudwatch_log_group" "this" {
  name = var.access_log_group_name
}