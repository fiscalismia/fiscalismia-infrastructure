resource "aws_s3_bucket" "storage_bucket" {
  bucket                = var.bucket_name
  bucket_prefix         = null
  force_destroy         = false
  object_lock_enabled   = false
  lifecycle {
    prevent_destroy = true
  }
}