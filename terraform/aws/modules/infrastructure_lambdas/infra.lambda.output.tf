
  output "apigw_route_throttler_arn" {
    description       = "Arn of the Infrastructure Lambda function"
    value             = aws_lambda_function.apigw_route_throttler.arn
  }
  output "notification_message_sender_arn" {
    description       = "Arn of the Infrastructure Lambda function"
    value             = aws_lambda_function.notification_message_sender.arn
  }
  output "terraform_module_destroyer_arn" {
    description       = "Arn of the Infrastructure Lambda function"
    value             = aws_lambda_function.terraform_module_destroyer.arn
  }