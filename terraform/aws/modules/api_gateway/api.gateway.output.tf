output "aws_api" {
  value = aws_apigatewayv2_api.aws_api
}
output "route_upload_img" {
  value = aws_apigatewayv2_route.upload_img
}
output "route_post_sheet_url" {
  value = aws_apigatewayv2_route.post_sheet_url
}
output "id" {
  value = aws_apigatewayv2_api.aws_api.id
}
output "stage" {
  value = var.default_stage
}