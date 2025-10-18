resource "aws_s3_bucket" "main" {
  bucket              = "my-bucket-a9c8ae4e2"
  object_lock_enabled = true
}