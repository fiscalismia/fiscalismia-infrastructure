# resource "aws_iam_role_policy" "github_actions_lambda_pipeline" {
#   name = "OpenID_Connect_GithubActions_LambdaPipelinePolicy"
#   role = aws_iam_role.github_actions_lambda_pipeline.name
#   policy = data.aws_iam_policy_document.github_actions_lambda_pipeline.json
# }

# resource "aws_iam_role_policy_attachment" "github_actions_lambda_pipeline" {
#   role       = aws_iam_role.github_actions_lambda_pipeline.name
#   policy_arn = aws_iam_role_policy.github_actions_lambda_pipeline.arn
# }

# Allow Lambda Pipeline Write Access to only Infrastructure Bucket and Lambda Prefix
resource "aws_iam_policy" "github_actions_lambda_pipeline" {
  name        = "OpenID_Connect_GithubActions_LambdaPipelinePolicy"
  description = "Policy for GitHub Actions to deploy Lambda functions to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/",
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/${var.lambda_s3_app_prefix}/*",
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/${var.lambda_s3_infra_prefix}/*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_lambda_pipeline.name
  policy_arn = aws_iam_policy.github_actions_lambda_pipeline.arn
}
