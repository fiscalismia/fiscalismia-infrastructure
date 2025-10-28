variable "apigw_route_throttler_lambda_arn" {}
variable "notification_message_sender_lambda_arn" {}
variable "terraform_module_destroyer_lambda_arn" {}
variable "sns_topic_budget_limit_exceeded_name" {
  description = "Name of the SNS Topic"
  type        = string
}
variable "sns_topic_apigw_route_throttling_name" {
  description = "Name of the SNS Topic"
  type        = string
}
variable "sns_topic_notification_message_sending_name" {
  description = "Name of the SNS Topic"
  type        = string
}