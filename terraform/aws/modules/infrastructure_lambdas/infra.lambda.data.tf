data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  SNS_TOPIC_ARN_NOTIFICATION_SENDER = "arn:aws:sns:${data.aws_region.current.region}:${data.aws_caller_identity.current.account_id}:${var.sns_topic_notification_message_sending_name}"
}