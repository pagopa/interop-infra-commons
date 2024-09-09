locals {
  openapi_abs_path       = abspath(var.openapi_relative_path)
  type_options           = var.api_version != null ? ["-t", var.type] : []
  api_version_options    = var.api_version != null ? ["-v", var.api_version] : []
  service_prefix_options = var.service_prefix != null ? ["-p"] : []
  swagger_options        = (var.env == "dev" && (var.api_name == "selfcare" || var.api_name == "api")) ? ["-s", "${path.module}/scripts/swagger-additional-paths.yaml"] : []

  maintenance_options = (var.maintenance_mode && var.maintenance_openapi_path != null) ? ["-m", abspath(var.maintenance_openapi_path)] : []
}

data "external" "openapi_integration" {
  program = concat(["python3", "${path.module}/scripts/openapi_integration.py",
    "-i", local.openapi_abs_path],
  local.type_options, local.api_version_options, local.service_prefix_options, local.swagger_options, local.maintenance_options)
}

locals {
  rest_apigw_name = (var.api_version != null ? format("interop-%s-%s-%s", var.api_name, var.api_version, var.env)
  : format("interop-%s-%s", var.api_name, var.env))
}

resource "aws_api_gateway_rest_api" "this" {
  depends_on = [data.external.openapi_integration]

  name = local.rest_apigw_name

  body               = data.external.openapi_integration.result.integrated_openapi_yaml
  put_rest_api_mode  = "overwrite"
  binary_media_types = ["multipart/form-data"]

  disable_execute_api_endpoint = true

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.this.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_rest_api.this.body,
      var.vpc_link_id,
      var.domain_name,
      var.service_prefix
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_api_gateway_stage" "env" {
  deployment_id = aws_api_gateway_deployment.this.id
  rest_api_id   = aws_api_gateway_rest_api.this.id

  stage_name = var.env

  variables = {
    VpcLinkId        = var.vpc_link_id
    CustomDomainName = var.domain_name
    ServicePrefix    = var.service_prefix
    ApiVersion       = var.api_version
  }

  dynamic "access_log_settings" {
    for_each = var.access_log_group_arn != null ? [var.access_log_group_arn] : []

    content {
      destination_arn = var.access_log_group_arn
      format = jsonencode({
        "apigwId"              = "$context.apiId"
        "requestId"            = "$context.requestId"
        "extendedRequestId"    = "$context.extendedRequestId"
        "sourceIp"             = "$context.identity.sourceIp"
        "requestTimeEpoch"     = "$context.requestTimeEpoch"
        "httpMethod"           = "$context.httpMethod"
        "requestPath"          = "$context.path"
        "resourcePath"         = "$context.resourcePath"
        "protocol"             = "$context.protocol"
        "userAgent"            = "$context.identity.userAgent"
        "status"               = "$context.status"
        "integrationLatencyMs" = "$context.integrationLatency"
        "integrationStatus"    = "$context.integrationStatus"
        "integrationError"     = "$context.integration.error"
        "responseLatencyMs"    = "$context.responseLatency"
        "responseLengthBytes"  = "$context.responseLength"
        "wafStatus"            = "$context.waf.status"
        "wafLatency"           = "$context.waf.latency"
        "wafError"             = "$context.waf.error"
        "xrayTraceId"          = "$context.xrayTraceId"
      })
    }
  }
}

resource "aws_api_gateway_method_settings" "all" {
  stage_name  = aws_api_gateway_stage.env.stage_name
  rest_api_id = aws_api_gateway_rest_api.this.id

  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "OFF"
  }
}

resource "aws_wafv2_web_acl_association" "this" {
  count = var.web_acl_arn != null ? 1 : 0

  resource_arn = aws_api_gateway_stage.env.arn
  web_acl_arn  = var.web_acl_arn
}
