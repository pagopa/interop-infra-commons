output "jwks_json_string" {
  description = "The computed JWKS in JSON string format"
  value       = data.external.kms_to_jwks.result.output
}
