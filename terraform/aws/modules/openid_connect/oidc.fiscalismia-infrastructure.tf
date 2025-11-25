# OIDC Role for Terraform Deployment
resource "aws_iam_role" "github_actions_terraform_aws_deployment" {
  name                 = "OpenID_Connect_GithubActions_TerraformPipeline"
  assume_role_policy   = data.aws_iam_policy_document.github_actions_terraform_aws_deployment.json
  max_session_duration = 3600 # 1 hour - limit session duration for security
}

data "aws_iam_policy_document" "github_actions_terraform_aws_deployment" {
  statement {
    sid     = "OpenIDConnectGithubActionsTerraformDeploymentAssumeRolePolicy"
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

resource "aws_iam_policy" "github_actions_terraform_aws_deployment_iam" {
  name        = "OpenID_Connect_GithubActions_TerraformPipeline_IAMPolicy"
  description = "Scoped IAM policy for GitHub Actions to deploy and destroy full Terraform infrastructure stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # IAM - Comprehensive role and policy management
      {
        Sid    = "IAMRoleManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:GetRole",
          "iam:UpdateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListRoleTags",
          "iam:ListInstanceProfilesForRole",
          "iam:PassRole"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LambdaExecutionRole_*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OpenID_Connect_GithubActions_*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CloudwatchLogging-SNSDelivery-FeedbackRole"
        ]
      },
      {
        Sid    = "IAMPolicyManagement"
        Effect = "Allow"
        Action = [
          "iam:CreatePolicy",
          "iam:DeletePolicy",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:ListPolicyVersions",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicyVersion",
          "iam:SetDefaultPolicyVersion",
          "iam:TagPolicy",
          "iam:UntagPolicy"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:policy/*"
        ]
      },
      {
        Sid    = "IAMRolePolicyAttachment"
        Effect = "Allow"
        Action = [
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:ListAttachedRolePolicies",
          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:ListRolePolicies"
        ]
        Resource = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/LambdaExecutionRole_*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/OpenID_Connect_GithubActions_*",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/CloudwatchLogging-SNSDelivery-FeedbackRole"
        ]
      },
      {
        Sid    = "IAMOpenIDConnectManagement"
        Effect = "Allow"
        Action = [
          "iam:CreateOpenIDConnectProvider",
          "iam:DeleteOpenIDConnectProvider",
          "iam:GetOpenIDConnectProvider",
          "iam:UpdateOpenIDConnectProviderThumbprint",
          "iam:TagOpenIDConnectProvider",
          "iam:UntagOpenIDConnectProvider",
          "iam:ListOpenIDConnectProviders",
          "iam:ListOpenIDConnectProviderTags"
        ]
        Resource = "*"
      },
    ]
    })
}

resource "aws_iam_policy" "github_actions_terraform_aws_deployment_serverless" {
  name        = "OpenID_Connect_GithubActions_TerraformPipeline_ServerlessPolicy"
  description = "Scoped Serverless policy for GitHub Actions to deploy and destroy full Terraform infrastructure stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [

      # Lambda - Full function and layer management
      {
        Sid    = "LambdaFunctionManagement"
        Effect = "Allow"
        Action = [
          "lambda:CreateFunction",
          "lambda:DeleteFunction",
          "lambda:GetFunction",
          "lambda:GetFunctionConfiguration",
          "lambda:UpdateFunctionCode",
          "lambda:UpdateFunctionConfiguration",
          "lambda:PublishVersion",
          "lambda:ListVersionsByFunction",
          "lambda:TagResource",
          "lambda:UntagResource",
          "lambda:ListTags",
          "lambda:InvokeFunction",
          "lambda:GetPolicy",
          "lambda:AddPermission",
          "lambda:RemovePermission",
          "lambda:GetFunctionCodeSigningConfig"
        ]
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:Fiscalismia_*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:Infrastructure_*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:function:Test_*"
        ]
      },
      {
        Sid    = "LambdaLayerManagement"
        Effect = "Allow"
        Action = [
          "lambda:PublishLayerVersion",
          "lambda:DeleteLayerVersion",
          "lambda:GetLayerVersion",
          "lambda:ListLayerVersions",
          "lambda:ListLayers"
        ]
        Resource = [
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:Fiscalismia_*",
          "arn:aws:lambda:${var.region}:${data.aws_caller_identity.current.account_id}:layer:Infrastructure_*"
        ]
      },
      {
        Sid    = "LambdaListOperations"
        Effect = "Allow"
        Action = [
          "lambda:ListFunctions",
          "lambda:ListEventSourceMappings"
        ]
        Resource = "*"
      },
      # API Gateway - Full HTTP API management
      {
        Sid    = "ApiGatewayManagement"
        Effect = "Allow"
        Action = [
          "apigateway:GET",
          "apigateway:POST",
          "apigateway:PUT",
          "apigateway:PATCH",
          "apigateway:DELETE",
          "apigateway:UpdateRestApiPolicy",
          "apigateway:TagResource"
        ]
        Resource = [
          "arn:aws:apigateway:${var.region}::/apis",
          "arn:aws:apigateway:${var.region}::/apis/*",
          "arn:aws:apigateway:${var.region}::/tags",
          "arn:aws:apigateway:${var.region}::/tags/*"
        ]
      },
      # SNS - Topic management for notifications
      {
        Sid    = "SNSTopicManagement"
        Effect = "Allow"
        Action = [
          "sns:CreateTopic",
          "sns:DeleteTopic",
          "sns:GetTopicAttributes",
          "sns:SetTopicAttributes",
          "sns:ListTopics",
          "sns:Subscribe",
          "sns:Unsubscribe",
          "sns:ListSubscriptions",
          "sns:ListSubscriptionsByTopic",
          "sns:GetSubscriptionAttributes",
          "sns:SetSubscriptionAttributes",
          "sns:TagResource",
          "sns:UntagResource",
          "sns:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:sns:${var.region}:${data.aws_caller_identity.current.account_id}:*"
        ]
      },
    ]
  })
}

resource "aws_iam_policy" "github_actions_terraform_aws_deployment_s3" {
  name        = "OpenID_Connect_GithubActions_TerraformPipeline_S3Policy"
  description = "Scoped S3 policy for GitHub Actions to deploy and destroy full Terraform infrastructure stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # S3 - Full management of buckets and objects
      {
        Sid    = "S3FullManagement"
        Effect = "Allow"
        Action = [
          "s3:CreateBucket",
          "s3:DeleteBucket",
          "s3:ListBucket",
          "s3:GetBucketLocation",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning",
          "s3:GetBucketAcl",
          "s3:PutBucketAcl",
          "s3:GetBucketCORS",
          "s3:PutBucketCORS",
          "s3:DeleteBucketCORS",
          "s3:GetBucketPolicy",
          "s3:PutBucketPolicy",
          "s3:DeleteBucketPolicy",
          "s3:GetBucketPublicAccessBlock",
          "s3:PutBucketPublicAccessBlock",
          "s3:GetLifecycleConfiguration",
          "s3:PutLifecycleConfiguration",
          "s3:DeleteLifecycleConfiguration",
          "s3:GetEncryptionConfiguration",
          "s3:PutEncryptionConfiguration",
          "s3:GetBucketOwnershipControls",
          "s3:PutBucketOwnershipControls",
          "s3:GetObjectLockConfiguration",
          "s3:PutObjectLockConfiguration",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucketVersions",
          "s3:GetBucketTagging",
          "s3:PutBucketTagging",
          "s3:GetBucketWebsite",
          "s3:GetAccelerateConfiguration",
          "s3:GetBucketRequestPayment",
          "s3:GetBucketLogging",
          "s3:GetReplicationConfiguration",
          "s3:GetBucketObjectLockConfiguration",
          "s3:PutBucketObjectLockConfiguration"
        ]
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name_prefix}*",
          "arn:aws:s3:::${var.s3_bucket_name_prefix}*/*"
        ]
      },
      {
        Sid    = "S3ListAllBuckets"
        Effect = "Allow"
        Action = [
          "s3:ListAllMyBuckets",
          "s3:GetBucketLocation"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3ReadWriteTerraformBackendState"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
        ]
        Resource = [
          "arn:aws:s3:::${var.terraform_state_bucket}",
          "arn:aws:s3:::${var.terraform_state_bucket}/*"
        ]
      },
    ]
    })
}

resource "aws_iam_policy" "github_actions_terraform_aws_deployment_general" {
  name        = "OpenID_Connect_GithubActions_TerraformPipeline_GeneralPolicy"
  description = "Scoped policy for GitHub Actions to deploy and destroy full Terraform infrastructure stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # Route 53 - DNS and health check management
      {
        Sid    = "Route53ListOperations"
        Effect = "Allow"
        Action = [
          "route53:ListHostedZones",
          "route53:ListHostedZonesByName",
        ]
        Resource = "*"
      },
      {
        Sid    = "Route53ZoneManagement"
        Effect = "Allow"
        Action = [
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:GetChange",
          "route53:ChangeResourceRecordSets",
          "route53:CreateHostedZone",
          "route53:DeleteHostedZone",
          "route53:ChangeTagsForResource",
          "route53:ListTagsForResource",
        ]
        Resource = [
          "arn:aws:route53:::hostedzone/*",
          "arn:aws:route53:::change/*"
        ]
      },
      {
        Sid    = "Route53HealthCheckManagement"
        Effect = "Allow"
        Action = [
          "route53:CreateHealthCheck",
          "route53:DeleteHealthCheck",
          "route53:GetHealthCheck",
          "route53:UpdateHealthCheck",
          "route53:ListHealthChecks",
          "route53:ChangeTagsForResource",
          "route53:ListTagsForResource"
        ]
        Resource = "*"
      },
      # ACM - Certificate management for TLS
      {
        Sid    = "ACMCertificateManagement"
        Effect = "Allow"
        Action = [
          "acm:RequestCertificate",
          "acm:DeleteCertificate",
          "acm:DescribeCertificate",
          "acm:ListCertificates",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate",
          "acm:ListTagsForCertificate"
        ]
        Resource = "*"
      },
      # Budgets - Cost budget and alarm management
      {
        Sid    = "BudgetsManagement"
        Effect = "Allow"
        Action = [
          "budgets:CreateBudget",
          "budgets:DeleteBudget",
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "budgets:DescribeBudgets",
          "budgets:ListTagsForResource",
          "budgets:TagResource"
        ]
        Resource = [
          "arn:aws:budgets::${data.aws_caller_identity.current.account_id}:budget/*"
        ]
      },
      # Secrets Manager - For Terraform Destroy Trigger Lambda
      {
        Sid    = "SecretsManagerReadAccess"
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:terraform-destroyer-trigger-token*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-infrastructure-master-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-loadbalancer-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-nat-gateway-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-demo-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-monitoring-instance-key-hcloud*",
          "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:fiscalismia-production-instances-key-hcloud*",
        ]
      },
      # General read-only access for Terraform state management
      {
        Sid    = "GetCallerIdentity"
        Effect = "Allow"
        Action = [
          "sts:GetCallerIdentity",
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_policy" "github_actions_terraform_aws_deployment_logging" {
  name        = "OpenID_Connect_GithubActions_TerraformPipeline_LoggingPolicy"
  description = "Scoped Logging policy for GitHub Actions to deploy and destroy full Terraform infrastructure stack"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # CloudWatch Logs - Log group management for Lambda
      {
        Sid    = "CloudWatchLogsManagement"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:DeleteLogGroup",
          "logs:PutRetentionPolicy",
          "logs:DeleteRetentionPolicy",
          "logs:ListTagsLogGroup",
          "logs:TagLogGroup",
          "logs:UntagLogGroup",
          "logs:ListTagsForResource"
        ]
        Resource = [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/Fiscalismia_*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/Infrastructure_*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/Test_*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sns/delivery/lambda/success*",
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/sns/delivery/lambda/failure*",
        ]
      },
      {
        Sid    = "CloudWatchLogsListOperations"
        Effect = "Allow"
        Action = [
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      # CloudWatch Alarms - Metric alarm management
      {
        Sid    = "CloudWatchAlarmManagement"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricAlarm",
          "cloudwatch:DeleteAlarms",
          "cloudwatch:DescribeAlarms",
          "cloudwatch:ListTagsForResource",
          "cloudwatch:TagResource",
          "cloudwatch:UntagResource"
        ]
        Resource = [
          "arn:aws:cloudwatch:${var.region}:${data.aws_caller_identity.current.account_id}:alarm:*"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform_aws_deployment_general" {
  role       = aws_iam_role.github_actions_terraform_aws_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_aws_deployment_general.arn
}
resource "aws_iam_role_policy_attachment" "github_actions_terraform_aws_deployment_iam" {
  role       = aws_iam_role.github_actions_terraform_aws_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_aws_deployment_iam.arn
}
resource "aws_iam_role_policy_attachment" "github_actions_terraform_aws_deployment_s3" {
  role       = aws_iam_role.github_actions_terraform_aws_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_aws_deployment_s3.arn
}
resource "aws_iam_role_policy_attachment" "github_actions_terraform_aws_deployment_serverless" {
  role       = aws_iam_role.github_actions_terraform_aws_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_aws_deployment_serverless.arn
}
resource "aws_iam_role_policy_attachment" "github_actions_terraform_aws_deployment_logging" {
  role       = aws_iam_role.github_actions_terraform_aws_deployment.name
  policy_arn = aws_iam_policy.github_actions_terraform_aws_deployment_logging.arn
}
