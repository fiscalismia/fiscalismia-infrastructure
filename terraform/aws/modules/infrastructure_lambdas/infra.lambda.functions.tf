resource "aws_lambda_function" "terraform_destroy_trigger" {
  function_name            = var.terraform_destroy_trigger_name
  description              = var.terraform_destroy_trigger_description
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/${var.terraform_destroy_trigger_name}.zip"
  role                     = var.lambda_execution_role_arn
  handler                  = var.handler_name
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
  layers = [
    aws_lambda_layer_version.infrastructure_layer.arn
  ]
}
resource "aws_lambda_function" "notification_message_sender" {
  function_name            = var.notification_message_sender_name
  description              = var.notification_message_sender_description
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/${var.notification_message_sender_name}.zip"
  role                     = var.lambda_execution_role_arn
  handler                  = var.handler_name
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = var.application_log_level
    system_log_level      = var.system_log_level
  }
  layers = [
    aws_lambda_layer_version.infrastructure_layer.arn
  ]
}
resource "aws_lambda_function" "apigw_route_throttler" {
  function_name            = var.apigw_route_throttler_name
  description              = var.apigw_route_throttler_description
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/${var.apigw_route_throttler_name}.zip"
  role                     = var.lambda_execution_role_arn
  handler                  = var.handler_name
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = var.application_log_level
    system_log_level      = var.system_log_level
  }
  layers = [
    aws_lambda_layer_version.infrastructure_layer.arn
  ]
}
resource "aws_lambda_function" "sandbox_function_testing" {
  function_name            = var.sandbox_function_testing_name
  description              = var.sandbox_function_testing_description
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/${var.sandbox_function_testing_name}.zip"
  role                     = var.lambda_execution_role_arn
  handler                  = var.handler_name
  timeout                  = 60   # seconds
  memory_size              = 512  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = var.application_log_level
    system_log_level      = var.system_log_level
  }
  layers = [
    aws_lambda_layer_version.infrastructure_layer.arn
  ]
}
