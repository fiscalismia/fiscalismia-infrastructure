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

  environment {
    variables = {
      IP_WHITELIST = "${var.ip_whitelist_lambda_processing}"
      API_KEY = "${var.secret_api_key}"
    }
  }
  layers = [
    aws_lambda_layer_version.dependency_layer.arn
  ]
}
