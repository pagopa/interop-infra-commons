resource "aws_cloudwatch_dashboard" "apigw" {
  dashboard_name = replace(format("apigw-%s", var.apigw_name), ".", "-")
  dashboard_body = templatefile("${path.module}/assets/SLA-Monitoring-apigw.json", {
    Region    = data.aws_region.current.name
    ApiGwName = var.apigw_name
  })
}

resource "aws_cloudwatch_dashboard" "single_endpoint" {
  dashboard_name = replace(format("apigw-%s", var.apigw_name), ".", "-")
  dashboard_body = templatefile("${path.module}/assets/SLA-Monitoring-single_endpoint.json", {
    Region    = data.aws_region.current.name
    ApiGwName = var.apigw_single_endpoint_name
  })
}
