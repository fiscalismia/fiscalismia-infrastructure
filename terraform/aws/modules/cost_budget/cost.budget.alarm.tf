locals {
  ACTUAL_VALUE     = "32"
  FORECASTED_VALUE = "24"
}

# Invokes destruction lambda, that actually destroys resources
resource "aws_budgets_budget" "total_actual_destruction" {
  name              = var.cost_budget_alarm_total_actual_name
  budget_type       = "COST"
  limit_amount      = local.ACTUAL_VALUE
  limit_unit        = "USD"
  time_period_start = "2025-11-01_00:00"
  time_period_end   = "2050-01-31_00:00"
  time_unit         = "MONTHLY"

  # Email Notification and Lambda Destruction Invocation
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_alarm_notification_email]
    subscriber_sns_topic_arns  = [var.sns_topic_arn_budget_limit_exceeded]
  }
}

# Invokes email sending that only notifies the user via mail
resource "aws_budgets_budget" "total_forecasted_notifaction" {
  name              = var.cost_budget_alarm_total_forecast_name
  budget_type       = "COST"
  limit_amount      = local.FORECASTED_VALUE
  limit_unit        = "USD"
  time_period_start = "2025-11-01_00:00"
  time_period_end   = "2050-01-31_00:00"
  time_unit         = "MONTHLY"

  # Email notification at 80% threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.budget_alarm_notification_email]
  }
  
  # SNS notification (for Lambda/Telegram) at 100% threshold
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_topic_arns  = [var.sns_topic_arn_budget_limit_exceeded]
  }
}