
resource "aws_iam_role" "sns_cloudwatch_feedback_role" {
  name = "CloudwatchLogging-SNSDelivery-FeedbackRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "sns.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Policy for SNS to write logs to CloudWatch
resource "aws_iam_role_policy" "sns_cloudwatch_feedback_policy" {
  name = "CloudwatchLogging-SNSDelivery-FeedbackPolicy"
  role = aws_iam_role.sns_cloudwatch_feedback_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:PutMetricFilter",
          "logs:PutRetentionPolicy"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}