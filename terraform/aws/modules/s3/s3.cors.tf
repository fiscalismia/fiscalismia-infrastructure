
resource "aws_s3_bucket_cors_configuration" "cross_origin_rules" {
  bucket = aws_s3_bucket.storage_bucket.id

  cors_rule {
    allowed_headers = ["content-type"]
    allowed_methods = ["POST"]
    allowed_origins = [var.fqdn]
    # Preflight request is an HTTP OPTIONS request sent by the browser to verify
    # if the server allows a cross-origin request before sending the actual request.
    max_age_seconds = 3000 # Cache preflight response for 3000 seconds
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = [var.fqdn]
    max_age_seconds = 3000 # Cache preflight response for 3000 seconds
  }
}
