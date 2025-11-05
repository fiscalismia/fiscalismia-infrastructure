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
variable "sns_topic_sandbox_sns_testing_name" {
  description = "Name of the SNS Topic"
  type        = string
}
variable "cloudwatch_log_retention_days" {
  description = "Number of days to retain CloudWatch logs for SNS delivery status"
  type        = number
}
variable "lambda_success_sample_rate" {
  description = "Percentage of successful Lambda deliveries to log (0-100). Lower = less cost."
  type        = number
  default     = 10  # Log 10% of successful deliveries
  validation {
    condition     = var.lambda_success_sample_rate >= 0 && var.lambda_success_sample_rate <= 100
    error_message = "Sample rate must be between 0 and 100."
  }
}