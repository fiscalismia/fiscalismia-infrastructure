output "budget_limit_exceeded_arn" {
  description = "ARN of the Budget Limit Exceeded Action SNS Topic"
  value       = aws_sns_topic.budget_limit_exceeded_action.arn
}
output "apigw_route_throttling_arn" {
  description = "ARN of the API Gateway Route Throttling SNS Topic"
  value       = aws_sns_topic.apigw_route_throttling.arn
}
output "notification_message_sending_arn" {
  description = "ARN of the Notification Message SNS Topic"
  value       = aws_sns_topic.notification_message_sending.arn
}
output "sandbox_sns_testing_arn" {
  description = "ARN of the Test SNS Topic"
  value       = aws_sns_topic.sns_topic_sandbox_sns_testing.arn
}