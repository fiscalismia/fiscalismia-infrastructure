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
resource "aws_iam_policy" "github_actions_lambda_pipeline_s3" {
  name        = "OpenID_Connect_GithubActions_LambdaPipeline_S3Policy"
  description = "Policy for S3 GitHub Actions to deploy Lambda functions to S3"

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

resource "aws_iam_policy" "github_actions_lambda_pipeline_update" {
  name        = "OpenID_Connect_GithubActions_LambdaPipeline_UpdatePolicy"
  description = "Policy for GitHub Actions to update Lambda functions and layers"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid = "UpdateLambdaFunctions"
        Effect = "Allow"
        Action = [
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration"
        ]
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:Test_*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.application_prefix}_*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:${var.infrastructure_prefix}_*"
        ]
      },
      {
        Sid = "UpdateLambdaLayers"
        Effect = "Allow"
        Action = [
          "lambda:PublishLayerVersion",
          "lambda:GetLayerVersion",
        ]
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:Test_*PythonDependencies*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:Test_*NodeJSDependencies*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:${var.application_prefix}_*PythonDependencies*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:${var.application_prefix}_*NodeJSDependencies*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:${var.infrastructure_prefix}_*PythonDependencies*",
        ]
      },
      {
        Sid = "ListLambdaFunctionsAndLayers"
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:ListLayerVersions",
          "lambda:ListLayers",
        ]
        Resource = [
          "*",
        ]
      },
    ],
  })
}


resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment_s3" {
  role       = aws_iam_role.github_actions_lambda_pipeline.name
  policy_arn = aws_iam_policy.github_actions_lambda_pipeline_s3.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_policy_attachment_update" {
  role       = aws_iam_role.github_actions_lambda_pipeline.name
  policy_arn = aws_iam_policy.github_actions_lambda_pipeline_update.arn
}