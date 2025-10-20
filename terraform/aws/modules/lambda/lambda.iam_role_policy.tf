# AWS IAM Role based policy for S3 access from lambda
data "aws_iam_policy_document" "lambda_s3_iam_role_access" {
  statement {
    sid       = "LambdaBucketReadAccess"
    effect    = "Allow"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}"]
  }

  statement {
    sid       = "LambdaObjectReadWriteAccess"
    effect    = "Allow"
    actions   = ["s3:GetObject", "s3:PutObject"]
    resources = ["arn:aws:s3:::${var.s3_bucket_name}/*"]
  }
}

resource "aws_iam_policy" "lambda_s3_iam_role_access" {
  name        = "LambdaS3_IAM_Role_Access_${var.function_purpose}"
  description = "Allow Lambda functions to access S3"
  policy      = data.aws_iam_policy_document.lambda_s3_iam_role_access.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_s3_iam_role_access.arn
}