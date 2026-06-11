variable "sns_topic_arn_apigw_route_throttling" {}
variable "api_gateway_id" {}
variable "api_gateway_stage" {}
variable "post_img_route" {}
variable "post_raw_data_route" {}
variable "post_img_lambda_name" {}
variable "post_raw_data_lambda_name" {}
variable "apigw_lambda_invocations_exceeded_post_img_route_name" {
  type = string
}
variable "apigw_lambda_invocations_exceeded_post_img_route_description" {
  type = string
}
variable "apigw_lambda_invocations_exceeded_post_raw_data_route_name" {
  type = string
}
variable "apigw_lambda_invocations_exceeded_post_raw_data_route_description" {
  type = string
}
variable "apigw_lambda_invocations_exceeded_post_img_route_threshold" {
  type = number
}
variable "apigw_lambda_invocations_exceeded_post_raw_data_route_threshold" {
  type = number
}