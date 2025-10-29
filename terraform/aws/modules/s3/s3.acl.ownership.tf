resource "aws_s3_bucket_ownership_controls" "storage_bucket" {
  bucket = aws_s3_bucket.storage_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced" # All Objects Belong to AWS Account Owning the Bucket
  }
}