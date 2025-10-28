resource "aws_sns_topic_subscription" "apigw_route_throttler_lambda" {
  topic_arn = aws_sns_topic.apigw_route_throttling.arn
  protocol  = "lambda"
  endpoint  = var.apigw_route_throttler_lambda_arn
}

resource "aws_sns_topic_subscription" "notification_message_sender_lambda" {
  topic_arn = aws_sns_topic.notification_message_sending.arn
  protocol  = "lambda"
  endpoint  = var.notification_message_sender_lambda_arn
}

resource "aws_sns_topic_subscription" "terraform_module_destroyer_lambda" {
  topic_arn = aws_sns_topic.budget_limit_exceeded_action.arn
  protocol  = "lambda"
  endpoint  = var.terraform_module_destroyer_lambda_arn
}