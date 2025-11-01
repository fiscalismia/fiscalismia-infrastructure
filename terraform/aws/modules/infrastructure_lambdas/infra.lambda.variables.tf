variable "lambda_execution_role_name" {}
variable "lambda_execution_role_arn" {}
variable "apigw_route_throttler_name" {}
variable "sandbox_function_testing_name" {}
variable "notification_message_sender_name" {}
variable "terraform_destroy_trigger_name" {}
variable "layer_name" {}
variable "layer_description" {}
variable "infrastructure_runtime" {}
variable "infrastructure_s3_bucket" {}
variable "infrastructure_s3_prefix" {}
variable "region" {}
variable "handler_name" {}
variable "cloudwatch_log_retention_days" {
  type = number
}