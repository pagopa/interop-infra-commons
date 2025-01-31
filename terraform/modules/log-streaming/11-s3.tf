
resource "aws_s3_bucket" "log_bucket" {
  bucket = var.s3_bucket_name
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.log_bucket.id
  acl    = "private"
}
