resource "aws_sns_topic" "budget_limit_exceeded_action" {
  name                        = var.sns_topic_budget_limit_exceeded_name
  lambda_success_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  lambda_success_feedback_sample_rate = var.lambda_success_sample_rate
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  tracing_config                      = var.enable_xray_tracing ? "Active" : "PassThrough"

  # AWS Budgets only support standard sns topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
resource "aws_sns_topic" "apigw_route_throttling" {
  name                        = var.sns_topic_apigw_route_throttling_name
  lambda_success_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  lambda_success_feedback_sample_rate = var.lambda_success_sample_rate
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  tracing_config                      = var.enable_xray_tracing ? "Active" : "PassThrough"

  # lambda subscribers do not support fifo topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
resource "aws_sns_topic" "notification_message_sending" {
  name                        = var.sns_topic_notification_message_sending_name
  lambda_success_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  lambda_success_feedback_sample_rate = var.lambda_success_sample_rate
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  tracing_config                      = var.enable_xray_tracing ? "Active" : "PassThrough"

  # lambda subscribers do not support fifo topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
# TESTING SNS TOPIC
resource "aws_sns_topic" "sns_topic_sandbox_sns_testing" {
  name                        = var.sns_topic_sandbox_sns_testing_name
  lambda_success_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  lambda_success_feedback_sample_rate = 100 # log all testing successes
  lambda_failure_feedback_role_arn    = aws_iam_role.sns_cloudwatch_feedback_role.arn
  tracing_config                      = "Active" # always enable tracing for testing
}