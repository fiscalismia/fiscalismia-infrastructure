resource "aws_s3_bucket_versioning" "storage_bucket" {
  bucket                    = aws_s3_bucket.storage_bucket.id
  mfa                       = null
  versioning_configuration {
    status     = var.versioning ? "Enabled" : "Disabled"
    mfa_delete = var.versioning ? "Disabled" : null  # mfa_delete should only be specified when versioning is enabled.
  }
}