# OIDC Role for Terraform Deployment
resource "aws_iam_role" "github_actions_terraform_hcloud_s3_backend" {
  name                 = "OpenID_Connect_GithubActions_TerraformHcloudBackendAccess"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_terraform_hcloud_s3_backend.json
  max_session_duration = 3600 # 1 hour - limit session duration for security
}

data "aws_iam_policy_document" "github_actions_terraform_hcloud_s3_backend" {
  statement {
    sid     = "OpenIDConnectGithubActionsTerraformHcloudS3BackendAssumeRolePolicy"
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
        "repo:${var.github_org}/${var.github_infrastructure_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_infrastructure_repo}:ref:refs/heads/pipeline_testing",
      ]
    }

    principals {
      type        = "Federated"
      identifiers = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/token.actions.githubusercontent.com"]
    }
  }
}

resource "aws_iam_policy" "github_actions_terraform_hcloud_s3_backend_s3" {
  name        = "OpenID_Connect_GithubActions_TerraformHcloudBackend_S3Policy"
  description = "Scoped S3 policy for GitHub Actions to update terraform state for hcloud deployments"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 - backend-state-access
      {
        Sid    = "S3ListTerraformBackendStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/hcloud/*",
        ]
      },
      {
        Sid    = "S3ReadWriteTerraformBackendState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/hcloud/*"
        ]
      },
    ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_s3_backend_s3" {
  role       = aws_iam_role.github_actions_terraform_hcloud_s3_backend.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_s3_backend_s3.arn
}
