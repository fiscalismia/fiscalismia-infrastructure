
resource "aws_s3_bucket_lifecycle_configuration" "deletion_and_archival" {
  bucket = aws_s3_bucket.storage_bucket.id

  rule {
    id = "default-rule"
    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
    status = "Enabled"
  }

  rule {
    id = "permanent-deletion-after-180-days"
    status = var.data_expiration ? "Enabled" : "Disabled"
    filter {}
    expiration {
      days = 180
    }
  }

  rule {
    id = "storage-class-transition"
    status = var.data_archival ? "Enabled" : "Disabled"
    filter {}

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    transition {
      days          = 60
      storage_class = "GLACIER_IR"
    }
    transition {
      days          = 150
      storage_class = "GLACIER"
    }
  }

}