# Resource Policy allowing Lambda to list all objects and read/write objects
data "aws_iam_policy_document" "lambda_s3_resource_policy_access" {
  statement {
    sid       = "LambdaBucketReadAccess"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.storage_bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = var.responsible_lambda_functions
    }
  }

  statement {
    sid       = "LambdaObjectReadWriteAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject",
                "s3:PutObject"]
    resources = ["${aws_s3_bucket.storage_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = var.responsible_lambda_functions
    }
  }
}

resource "aws_s3_bucket_policy" "resource_policy" {
  bucket = var.bucket_name
  policy = data.aws_iam_policy_document.lambda_s3_resource_policy_access.json
}