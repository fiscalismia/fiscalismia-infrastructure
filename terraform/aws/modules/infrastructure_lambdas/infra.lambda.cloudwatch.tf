### INFO: works out of the box if the log group adheres to the standard /aws/lambda/$function_name
resource "aws_cloudwatch_log_group" "apigw_route_throttler" {
  name              = "/aws/lambda/${var.apigw_route_throttler_name}"
  retention_in_days = var.cloudwatch_log_retention_days
}
resource "aws_cloudwatch_log_group" "notification_message_sender" {
  name              = "/aws/lambda/${var.notification_message_sender_name}"
  retention_in_days = var.cloudwatch_log_retention_days
}
resource "aws_cloudwatch_log_group" "terraform_destroy_trigger" {
  name              = "/aws/lambda/${var.terraform_destroy_trigger_name}"
  retention_in_days = var.cloudwatch_log_retention_days
}