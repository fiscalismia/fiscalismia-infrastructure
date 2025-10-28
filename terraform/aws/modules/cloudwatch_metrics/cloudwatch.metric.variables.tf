variable "sns_topic_arn_apigw_route_throttling" {}
variable "apigw_count_exceeded_post_img_route_name" {
  type = string
}
variable "apigw_count_exceeded_post_img_route_description" {
  type = string
}
variable "apigw_count_exceeded_post_raw_data_route_name" {
  type = string
}
variable "apigw_count_exceeded_post_raw_data_route_description" {
  type = string
}
variable "apigw_count_exceeded_post_img_route_threshold" {
  type = number
}
variable "apigw_count_exceeded_post_raw_data_route_threshold" {
  type = number
}