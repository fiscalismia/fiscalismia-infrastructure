# OIDC Role for Terraform Deployment
resource "aws_iam_role" "github_actions_terraform_hcloud_deployment" {
  name                 = "OpenID_Connect_GithubActions_TerraformHcloudDeploymentAccess"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_terraform_hcloud_deployment.json
  max_session_duration = 3600 # 1 hour - limit session duration for security
}

data "aws_iam_policy_document" "github_actions_terraform_hcloud_deployment" {
  statement {
    sid     = "OpenIDConnectGithubActionsTerraformHcloudDeploymentAssumeRolePolicy"
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

resource "aws_iam_policy" "github_actions_terraform_hcloud_deployment_s3" {
  name        = "OpenID_Connect_GithubActions_TerraformHcloudDeployment_S3Policy"
  description = "Scoped S3 policy for GitHub Actions to update terraform state for hcloud deployments and access PKI setup data"

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
      # S3 - read PKI setup files
      {
        Sid    = "S3ListInfrastructurePkiBucketPrefix"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${var.infrastructure_s3_bucket}",
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/pki/*",
        ]
      },
      {
        Sid    = "S3ReadInfrastructurePkiBucketPrefix"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.infrastructure_s3_bucket}/pki/*",
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

resource "aws_iam_policy" "github_actions_terraform_hcloud_deployment_secretsmgr" {
  name        = "OpenID_Connect_GithubActions_TerraformHcloudDeployment_SecretsManagerPolicy"
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

resource "aws_iam_policy" "github_actions_terraform_hcloud_deployment_parameter_store" {
  name        = "OpenID_Connect_GithubActions_TerraformHcloudDeployment_ParameterStorePolicy"
  description = "Scoped Parameter Store Access for hcloud deployment secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Parameter Store Access for hardcoded Tokens and SecureStrings not rotated automatically
      {
        Sid    = "ParameterStoreReadAccess"
        Effect = "Allow"
        Action = [
          "ssm:GetParameter"
        ]
        Resource = [
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/pki/intermediate-ca-key.enc",
          "arn:aws:ssm:${var.region}:${data.aws_caller_identity.current.account_id}:parameter/pki/intermediate_ca_key_password",
        ]
      },
      {
        Sid    = "ParameterStoreKMSDecrypt"
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = [
          "arn:aws:kms:${var.region}:${data.aws_caller_identity.current.account_id}:key/alias/aws/ssm"
        ]
      },
    ]
    })
}




resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_deployment_s3" {
  role       = aws_iam_role.github_actions_terraform_hcloud_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_deployment_s3.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_deployment_secretsmgr" {
  role       = aws_iam_role.github_actions_terraform_hcloud_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_deployment_secretsmgr.arn
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_hcloud_deployment_parameter_store" {
  role       = aws_iam_role.github_actions_terraform_hcloud_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_hcloud_deployment_parameter_store.arn
}
