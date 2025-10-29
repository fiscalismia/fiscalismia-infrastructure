resource "aws_s3_bucket_lifecycle_configuration" "deletion_and_archival" {
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    id     = "abort-incomplete-multipart-uploads"
    status = "Enabled"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  dynamic "rule" {
    for_each = var.data_infrequent_access ? [1] : []
    content {
      id     = "transition-to-infrequent-access"
      status = "Enabled"
      filter {}

      transition {
        days          = var.data_infrequent_access_days
        storage_class = "STANDARD_IA"
      }
    }
  }

  dynamic "rule" {
    for_each = var.data_archival ? [1] : []
    content {
      id     = "transition-to-glacier-archive"
      status = "Enabled"
      filter {}

      transition {
        days          = var.data_archival_days
        storage_class = "GLACIER_IR"
      }
      transition {
        days          = var.data_archival_days + 90
        storage_class = "GLACIER"
      }
    }
  }

  dynamic "rule" {
    for_each = var.data_expiration ? [1] : []
    content {
      id     = "permanent-deletion"
      status = "Enabled"
      filter {}

      expiration {
        days = var.data_expiration_days
      }
    }
  }
}