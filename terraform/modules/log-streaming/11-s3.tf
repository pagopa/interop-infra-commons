
resource "aws_s3_bucket" "this" {
  bucket = var.s3_bucket_name
  tags   = var.s3_bucket_tags
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = "private"
}
