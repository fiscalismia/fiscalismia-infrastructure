resource "aws_sns_topic" "budget_limit_exceeded_action" {
  name                        = var.sns_topic_budget_limit_exceeded_name
  # AWS Budgets only support standard sns topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
resource "aws_sns_topic" "apigw_route_throttling" {
  name                        = var.sns_topic_apigw_route_throttling_name
  # lambda subscribers do not support fifo topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
resource "aws_sns_topic" "notification_message_sending" {
  name                        = var.sns_topic_notification_message_sending_name
  # lambda subscribers do not support fifo topics
  # fifo_topic                  = true
  # content_based_deduplication = true
}
# TESTING
resource "aws_sns_topic" "sns_topic_sandbox_sns_testing" {
  name                        = var.sns_topic_sandbox_sns_testing_name
}