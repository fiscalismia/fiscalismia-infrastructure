output "aws_api" {
  value = aws_apigatewayv2_api.aws_api
}
output "route_upload_img" {
  value = aws_apigatewayv2_route.upload_img
}
output "route_post_etl_raw_data" {
  value = aws_apigatewayv2_route.post_raw_data_etl
}
output "id" {
  value = aws_apigatewayv2_api.aws_api.id
}
output "stage" {
  value = var.default_stage
}