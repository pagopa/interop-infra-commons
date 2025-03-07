resource "aws_s3_object" "glue_script" {
  bucket = var.s3_script_bucket
  key    = var.script_key
  source = var.script_path
}