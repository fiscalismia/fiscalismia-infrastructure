resource "aws_s3_bucket" "storage_bucket" {
  bucket = var.bucket_name
  force_destroy = false
  object_lock_enabled = false

  tags = {
    Name        = var.bucket_description
  }

  lifecycle {
    prevent_destroy = true
  }
}