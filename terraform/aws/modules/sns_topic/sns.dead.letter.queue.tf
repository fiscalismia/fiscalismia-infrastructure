# TODO verify
resource "aws_sqs_queue" "notification_dlq" {
  name = "${var.sns_topic_notification_message_sending_name}-dlq"
}

# TODO verify
resource "aws_sns_topic_subscription" "notification_lambda" {
  topic_arn = aws_sns_topic.notification_message_sending.arn
  protocol  = "lambda"
  endpoint  = var.notification_message_sender_lambda_arn

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.notification_dlq.arn
  })
}