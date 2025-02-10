module "log_streaming_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-log-streaming-s3-bucket-%s", var.module_resource_prefix, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  # TODO - add Object lock configurabile (modalità compliance o governance [enum]) -> da ragionare
  object_lock_enabled = var.s3_bucket_object_lock_enabled
  object_lock_configuration = {
    mode = var.s3_bucket_object_lock_mode
  }
  versioning = {
    enabled = true
  }

  tags = var.s3_bucket_tags
}