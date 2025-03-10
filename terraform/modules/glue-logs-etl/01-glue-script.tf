locals {
  glue_job_script_name = "glue_job_script.py"
}

data "aws_s3_bucket" "glue_script_bucket" {
  bucket = var.s3_script_target_bucket
}

resource "aws_s3_object" "glue_script" {
  bucket = data.aws_s3_bucket.glue_script_bucket.bucket # Name of the bucket to put the file in. Alternatively, an S3 access point ARN can be specified.
  key    = local.glue_job_script_name                   #  Name of the object once it is in the bucket.
  source = "${path.module}/scripts/${local.glue_job_script_name}"

  etag = filemd5("${path.module}/scripts/${local.glue_job_script_name}")

  tags = var.glue_script_tags
}