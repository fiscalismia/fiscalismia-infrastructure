resource "aws_budgets_budget" "total_actual" {
  name              = var.cost_budget_alarm_total_actual_name
  budget_type       = "COST"
  limit_amount      = "50"
  limit_unit        = "USD"
  time_period_start = "2025-11-01_00:00"
  time_period_end   = "2050-01-31_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_topic_arns  = [var.sns_topic_arn_budget_limit_exceeded]
  }
}

resource "aws_budgets_budget" "total_forecasted" {
  name              = var.cost_budget_alarm_total_forecast_name
  budget_type       = "COST"
  limit_amount      = "30"
  limit_unit        = "USD"
  time_period_start = "2025-11-01_00:00"
  time_period_end   = "2050-01-31_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = [var.forecasted_budget_notification_email]
  }
}