resource "aws_cloudwatch_log_group" "apigw_route_throttler" {
  name              = "/aws/lambda/${aws_lambda_function.apigw_route_throttler.name}"
  retention_in_days = var.cloudwatch_log_retention_days
}
resource "aws_cloudwatch_log_group" "notification_message_sender" {
  name              = "/aws/lambda/${aws_lambda_function.notification_message_sender.name}"
  retention_in_days = var.cloudwatch_log_retention_days
}
resource "aws_cloudwatch_log_group" "terraform_destroy_trigger" {
  name              = "/aws/lambda/${aws_lambda_function.terraform_destroy_trigger.name}"
  retention_in_days = var.cloudwatch_log_retention_days
}