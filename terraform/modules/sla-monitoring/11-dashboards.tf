resource "aws_cloudwatch_dashboard" "apigw" {
  dashboard_name = "${var.dashboard_prefix}-apigw-${replace(var.apigw_name, ".", "-")}"
  dashboard_body = templatefile("${path.module}/assets/SLA-Monitoring-apigw.json", {
    Region     = data.aws_region.current.name
    ApiGwName  = var.apigw_name
    ApiGwStage = var.api_stage
  })
}

resource "aws_cloudwatch_dashboard" "single_endpoint" {
  count          = var.apigw_single_endpoint_name != "" ? 1 : 0
  dashboard_name = "${var.dashboard_prefix}-apigw-single-endpoint-${replace(var.apigw_single_endpoint_name, ".", "-")}"
  dashboard_body = templatefile("${path.module}/assets/SLA-Monitoring-single_endpoint.json", {
    Region     = data.aws_region.current.name
    ApiGwName  = var.apigw_single_endpoint_name
    ApiGwStage = var.api_stage
  })
}