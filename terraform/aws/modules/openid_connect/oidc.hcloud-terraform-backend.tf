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
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_infrastructure_repo}:ref:refs/heads/main",
        "repo:${var.github_org}/${var.github_infrastructure_repo}:ref:refs/heads/pipeline_testing",
        "repo:${var.github_org}/${var.github_infrastructure_repo}:pull_request",
        # Adds environment support for OIDC to allow for manual approval of terraform apply jobs
        "repo:${var.github_org}/${var.github_infrastructure_repo}:environment:prod",
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
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/aws/*",
        ]
      },
      {
        Sid    = "S3ReadTerraformBackendState"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/aws/*",
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/hcloud/*",
        ]
      },
      {
        Sid    = "S3WriteTerraformBackendState"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}/fiscalismia-infrastructure/hcloud/*",
        ]
      },
    ]
    })
}

resource "aws_iam_policy" "github_actions_terraform_hcloud_s3_backend_secretsmgr" {
  name        = "OpenID_Connect_GithubActions_TerraformHcloudBackend_SecretsManagerPolicy"
  description = "Scoped Secrets Manager Access for hcloud deployment secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Secrets Manager - For SSH Public Keys to Provision Hcloud Servers
      {
        Sid    = "SecretsManagerReadAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-backend/.env*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-infrastructure-master-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-production-instances-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-loadbalancer-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-demo-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-nat-gateway-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-monitoring-instance-key-hcloud*",
        ]
      },
    ]
    })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_s3_backend_s3" {
  role       = aws_iam_role.github_actions_terraform_hcloud_s3_backend.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_s3_backend_s3.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_s3_backend_secretsmgr" {
  role       = aws_iam_role.github_actions_terraform_hcloud_s3_backend.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_s3_backend_secretsmgr.arn
}
