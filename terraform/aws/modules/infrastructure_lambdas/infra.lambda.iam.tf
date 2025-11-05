# CloudWatch Logs policy
resource "aws_iam_policy" "lambda_cloudwatch_logging_infra" {
  name        = "CloudwatchLogging-InfrastructurePolicy"
  path        = "/"
  description = "IAM policy for logging from Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}
resource "aws_iam_role_policy_attachment" "lambda_logs" {
  role       = var.lambda_execution_role_name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logging_infra.arn
}