resource "aws_s3_object" "openapi" {
  depends_on = [data.external.openapi_integration]

  count = var.openapi_s3_bucket_name != null && var.openapi_s3_object_key != null ? 1 : 0

  bucket = var.openapi_s3_bucket_name
  key    = var.openapi_s3_object_key

  content = data.external.openapi_integration.result.integrated_openapi_yaml

  source_hash = md5(data.external.openapi_integration.result.integrated_openapi_yaml)
}
