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