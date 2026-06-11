################ Allow SNS to invoke Lambdas #################
resource "aws_lambda_permission" "apigw_route_throttler_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.infrastructure_lambdas.apigw_route_throttler_arn
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns_topics.apigw_route_throttling_arn
}
resource "aws_lambda_permission" "notification_message_sender_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.infrastructure_lambdas.notification_message_sender_arn
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns_topics.notification_message_sending_arn
}
resource "aws_lambda_permission" "terraform_destroy_trigger_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.infrastructure_lambdas.terraform_destroy_trigger_arn
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns_topics.budget_limit_exceeded_arn
}
# TEST SANDBOX LAMBDA FUNCTION
resource "aws_lambda_permission" "sandbox_function_testing_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.infrastructure_lambdas.sandbox_function_testing_arn
  principal     = "sns.amazonaws.com"
  source_arn    = module.sns_topics.sandbox_sns_testing_arn
}
