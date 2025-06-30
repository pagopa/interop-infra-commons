output "apigw_name" {
  description = "Name of the APIGW managed by this module"
  value       = aws_api_gateway_rest_api.this.name
}

output "apigw_id" {
  description = "ID of the APIGW managed by this module"
  value       = aws_api_gateway_rest_api.this.id
}

output "apigw_stage_name" {
  description = "Name of the stage of the APIGW managed by this module"
  value       = aws_api_gateway_stage.env.stage_name
}