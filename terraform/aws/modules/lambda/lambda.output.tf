output "function_name" {
  value = aws_lambda_function.api_gw_func.function_name
}
output "invoke_arn" {
  value = aws_lambda_function.api_gw_func.invoke_arn
}
output "lambda_role_arn" {
  value = aws_iam_role.lambda_execution_role.arn
}