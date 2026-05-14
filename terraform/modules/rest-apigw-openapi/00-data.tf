data "aws_cloudwatch_log_group" "this" {
  count = var.access_log_group_name != null ? 1 : 0
  
  name = var.access_log_group_name
}