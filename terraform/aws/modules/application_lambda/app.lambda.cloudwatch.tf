### INFO: works out of the box if the log group adheres to the standard /aws/lambda/$function_name
resource "aws_cloudwatch_log_group" "app_log_grp" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.cloudwatch_log_retention_days
}