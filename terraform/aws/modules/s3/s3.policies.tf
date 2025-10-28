# Resource Policy allowing Lambda to list all objects and read/write objects
data "aws_iam_policy_document" "lambda_s3_resource_policy_access" {
  statement {
    sid       = "LambdaBucketReadAccess"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.storage_bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = var.lambda_execution_role_arns
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
      identifiers = var.lambda_execution_role_arns
    }
  }
}

resource "aws_s3_bucket_policy" "resource_policy" {
  bucket = aws_s3_bucket.storage_bucket.id
  policy = data.aws_iam_policy_document.lambda_s3_resource_policy_access.json
}