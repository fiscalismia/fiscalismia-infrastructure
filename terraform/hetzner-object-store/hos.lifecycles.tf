resource "aws_s3_bucket_lifecycle_configuration" "main" {
  bucket = aws_s3_bucket.main.id
  # Required for Hetzner compatibility
  transition_default_minimum_object_size = ""
  rule {
    id     = "expire-7d"
    status = "Enabled"

    expiration {
      days = 7
    }
  }
}