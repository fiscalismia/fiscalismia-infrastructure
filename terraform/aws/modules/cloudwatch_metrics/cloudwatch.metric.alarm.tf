# see https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-metrics-and-dimensions.html
# see https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html
resource "aws_cloudwatch_metric_alarm" "apigw_count_exceeded_post_img_route" {
  alarm_name                = var.apigw_count_exceeded_post_img_route_name
  alarm_description         = var.apigw_count_exceeded_post_img_route_description
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 3  # number of periods in which the sum of count has to be exceeded
  period                    = 60 # seconds
  metric_name               = "Count"
  namespace                 = "AWS/ApiGateway"
  statistic                 = "Sum"
  threshold                 = var.apigw_count_exceeded_post_img_route_threshold
  actions_enabled           = true
  alarm_actions             = [var.sns_topic_arn_apigw_route_throttling]
}

resource "aws_cloudwatch_metric_alarm" "apigw_count_exceeded_post_raw_data_route" {
  alarm_name                = var.apigw_count_exceeded_post_raw_data_route_name
  alarm_description         = var.apigw_count_exceeded_post_raw_data_route_description
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 3  # number of periods in which the sum of count has to be exceeded
  period                    = 60 # seconds
  metric_name               = "Count"
  namespace                 = "AWS/ApiGateway"
  statistic                 = "Sum"
  threshold                 = var.apigw_count_exceeded_post_raw_data_route_threshold
  actions_enabled           = true
  alarm_actions             = [var.sns_topic_arn_apigw_route_throttling]
}