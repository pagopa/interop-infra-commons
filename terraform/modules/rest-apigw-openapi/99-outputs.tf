output "apigw_name" {
  description = "Name of the APIGW managed by this module"
  value       = aws_api_gateway_rest_api.this.name
}

output "apigw_id" {
  description = "ID of the APIGW managed by this module"
  value       = aws_api_gateway_rest_api.this.id
}
