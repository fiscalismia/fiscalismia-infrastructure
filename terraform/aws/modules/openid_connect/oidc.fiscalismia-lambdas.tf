resource "aws_iam_role" "github_actions_lambda_pipeline" {
  name = "OpenID_Connect_GithubActions_LambdaPipeline"
  assume_role_policy = data.aws_iam_policy_document.github_actions_lambda_pipeline.json
}

data "aws_iam_policy_document" "github_actions_lambda_pipeline" {
  statement {
    sid     = "OpenIDConnectGithubActionsLambdaPipelineAssumeRolePolicy"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"

      values = [
        "repo:${var.github_org}/${var.github_lambda_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_lambda_repo}:ref:refs/heads/pipeline_testing",
      ]
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
  }
}

# Allow Lambda Pipeline Write Access to only Infrastructure Bucket and Lambda Prefix
resource "aws_iam_policy" "github_actions_lambda_pipeline" {
  name        = "OpenID_Connect_GithubActions_LambdaPipelinePolicy"
  description = "Policy for GitHub Actions to deploy Lambda functions to S3"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "AccessInfrastructureLambdaPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          "arn:aws:s3:::${var.infrastructure_s3_bucket}",
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/${var.lambda_s3_app_prefix}/*",
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/${var.lambda_s3_infra_prefix}/*"
        ]
      },
      {
        Sid = "ListAllBucketNamesInAccount"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
        ]
        Resource = [
          "arn:aws:s3:::*",
        ]
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment" {
  role       = aws_iam_role.github_actions_lambda_pipeline.name
  policy_arn = aws_iam_policy.github_actions_lambda_pipeline.arn
}
