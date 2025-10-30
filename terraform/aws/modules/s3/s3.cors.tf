# resource "aws_s3_bucket_cors_configuration" "cross_origin_rules" {
#   bucket = aws_s3_bucket.storage_bucket.id

#   cors_rule {
#     allowed_headers = ["content-type"]
#     allowed_methods = ["POST"]
#     allowed_origins = [var.fqdn != null ? var.fqdn : "*"]
#     # Preflight request is an HTTP OPTIONS request sent by the browser to verify
#     # if the server allows a cross-origin request before sending the actual request.
#     max_age_seconds = 3000 # Cache preflight response for 3000 seconds
#   }

#   cors_rule {
#     allowed_headers = ["*"]
#     allowed_methods = ["GET"]
#     allowed_origins = [var.fqdn != null ? var.fqdn : "*"]
#     max_age_seconds = 3000 # Cache preflight response for 3000 seconds
#   }
# }

# see: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_cors_configuration

locals {
  cross_origin_resource_sharing_access_from_website = {
    allowed_headers = [
      "Authorization",                # Required for Authorization
      "Content-Length",               # Specifies the size of the body in bytes
      "Content-Type",                 # Indicates the media type of the resource
      "Range",                        # Allows partial content requests
      "amz-sdk-invocation-id",        # For tracking SDK calls
      "amz-sdk-request",              # For tracking SDK requests (attemps, max)
      "x-amz-content-sha256",         # Required for request signature verification
      "x-amz-expected-bucket-owner",  # Bucket Owner Account ID Security feature
      "x-amz-date",                   # Required for request timestamp validation
      "x-amz-user-agent",             # Client identification
      "x-amz-security-token"          # Required when using temporary credentials
    ]
    allowed_methods = ["GET", "HEAD", "POST"]
    allowed_origins = [
      # DO NOT include trailing forward slashes in URLs
      "http://localhost:3001",         # TODO local development frontend
      "http://localhost:3002",         # TODO local development backend
      "http://localhost:4173",         # TODO local development vite
      "${var.fqdn != null ? var.fqdn : ""}", # either FQDN or empty string
    ]
    expose_headers  = [
      "x-amz-server-side-encryption", # Indicates the encryption method used
      "x-amz-request-id",             # Helpful for troubleshooting requests
      "x-amz-id-2",                   # Extended request identifier for AWS support
      "ETag",                         # Essential for caching and version verification
      "Content-Length",               # Required for progress indicators and download management
      "Content-Range"                 # Needed for range requests (partial downloads)
    ]
  }
}

resource "aws_s3_bucket_cors_configuration" "cross_origin_rules" {
  bucket = aws_s3_bucket.storage_bucket.id

  cors_rule {
    allowed_headers = local.cross_origin_resource_sharing_access_from_website.allowed_headers
    allowed_methods = local.cross_origin_resource_sharing_access_from_website.allowed_methods
    allowed_origins = local.cross_origin_resource_sharing_access_from_website.allowed_origins
    expose_headers  = local.cross_origin_resource_sharing_access_from_website.expose_headers
  }
}