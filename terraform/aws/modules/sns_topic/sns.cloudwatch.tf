# These are created automatically by SNS but we define them for better control

resource "aws_cloudwatch_log_group" "sns_lambda_success" {
  name              = "/aws/sns/delivery/lambda/success"
  retention_in_days = var.cloudwatch_log_retention_days
}

resource "aws_cloudwatch_log_group" "sns_lambda_failure" {
  name              = "/aws/sns/delivery/lambda/failure"
  retention_in_days = var.cloudwatch_log_retention_days
}