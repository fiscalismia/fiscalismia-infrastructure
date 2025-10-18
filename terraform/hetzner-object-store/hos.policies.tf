resource "aws_s3_bucket_policy" "main" {
  bucket = aws_s3_bucket.main.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect    = "Allow",
        Principal = "*",
        Action    = ["s3:GetObject"],
        # add your project id
        Resource  = ["arn:aws:s3:::${aws_s3_bucket.main.bucket}/*"]
      }
    ]
  })
}