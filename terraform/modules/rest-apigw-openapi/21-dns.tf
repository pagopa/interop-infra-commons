resource "aws_api_gateway_base_path_mapping" "this" {
  count = var.enable_base_path_mapping && var.domain_name != null ? 1 : 0

  stage_name  = aws_api_gateway_stage.env.stage_name
  domain_name = var.domain_name
  api_id      = aws_api_gateway_rest_api.this.id

  base_path = var.api_version != null ? var.api_version : ""
}

