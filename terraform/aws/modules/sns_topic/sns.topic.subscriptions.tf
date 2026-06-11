
###################### SNS TOPIC SUBSCRIPTIONS #######################
resource "aws_sns_topic_subscription" "apigw_route_throttler_lambda" {
  topic_arn = aws_sns_topic.apigw_route_throttling.arn
  protocol  = "lambda"
  endpoint  = var.apigw_route_throttler_arn
}
resource "aws_sns_topic_subscription" "notification_message_sender_lambda" {
  topic_arn = aws_sns_topic.notification_message_sending.arn
  protocol  = "lambda"
  endpoint  = var.notification_message_sender_arn
}
resource "aws_sns_topic_subscription" "terraform_destroy_trigger_lambda" {
  topic_arn = aws_sns_topic.budget_limit_exceeded_action.arn
  protocol  = "lambda"
  endpoint  = var.terraform_destroy_trigger_arn
}
# TEST SNS SUBSCRIPTION
resource "aws_sns_topic_subscription" "sandbox_function_testing_lambda" {
  topic_arn = aws_sns_topic.sns_topic_sandbox_sns_testing.arn
  protocol  = "lambda"
  endpoint  = var.sandbox_function_testing_arn
}