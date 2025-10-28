resource "aws_lambda_function" "terraform_destroy_trigger" {
  function_name            = "TerraformDestroyTrigger"
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/TerraformDestroyTrigger.zip"
  role                     = var.lambda_execution_role_name
  handler                  = "index.handler"
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
}
resource "aws_lambda_function" "notification_message_sender" {
  function_name            = "NotificationMessageSender"
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/NotificationMessageSender.zip"
  role                     = var.lambda_execution_role_name
  handler                  = "index.handler"
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
}

resource "aws_lambda_function" "apigw_route_throttler" {
  function_name            = "ApiGatewayRouteThrottler"
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/ApiGatewayRouteThrottler.zip"
  role                     = var.lambda_execution_role_name
  handler                  = "index.handler"
  timeout                  = 30   # seconds
  memory_size              = 256  # MB
  runtime                  = var.infrastructure_runtime

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = "INFO"
    system_log_level      = "WARN"
  }
}

