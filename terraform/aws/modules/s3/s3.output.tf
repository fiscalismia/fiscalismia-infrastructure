output "bucket_name" {
  value = aws_s3_bucket.storage_bucket.id
}
output "bucket_arn" {
  value = aws_s3_bucket.storage_bucket.arn
}