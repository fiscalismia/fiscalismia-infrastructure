resource "aws_lambda_function" "api_gw_func" {
  function_name            = var.function_name
  description              = var.function_description
  s3_bucket                = var.infrastructure_s3_bucket
  s3_key                   = "${var.infrastructure_s3_prefix}/${var.function_name}.zip"
  role                     = var.lambda_execution_role_arn
  handler                  = var.handler_name
  timeout                  = var.timeout_seconds
  runtime                  = var.runtime_env
  memory_size              = var.memory_size

  # Advanced logging configuration
  logging_config {
    log_format            = "JSON"
    application_log_level = var.application_log_level
    system_log_level      = var.system_log_level
  }
  environment {
    variables = {
      IP_WHITELIST = "${var.ip_whitelist_lambda_processing}"
    }
  }
  layers = [
    aws_lambda_layer_version.dependency_layer.arn
  ]
}
