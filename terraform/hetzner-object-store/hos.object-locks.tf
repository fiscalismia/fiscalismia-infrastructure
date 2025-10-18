resource "aws_s3_bucket_object_lock_configuration" "example" {
  bucket = aws_s3_bucket.main.id

  rule {
    default_retention {
      mode = "COMPLIANCE"
      days = 7
    }
  }
}
