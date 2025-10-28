resource "aws_apigatewayv2_api" "aws_api" {
  name          = var.api_name
  description   = var.api_description
  protocol_type = "HTTP"

  cors_configuration {
    allow_headers     = ["content-type"] # other values "x-amz-date", "authorization", "x-api-key", "x-amz-security-token", "x-amz-user-agent"
    allow_methods     = ["POST"]
    allow_origins     = [var.fqdn]
    allow_credentials = false # For sending cookies or credentials
    expose_headers    = [] # Headers exposed to the browser. check allow_headers for values
    max_age           = 3600 # Cache CORS preflight response for 1 hour
  }
}
####################################################################################
# If you add another route, refactor these resources to a dynamic loop
####################################################################################
resource "aws_apigatewayv2_integration" "upload_img" {
  api_id                    = aws_apigatewayv2_api.aws_api.id
  integration_type          = "AWS_PROXY"
  connection_type           = "INTERNET"
  description               = "Lambda Upload Image Integration"
  integration_method        = "POST"
  integration_uri           = var.lambda_invoke_arn_upload_img
}

resource "aws_apigatewayv2_integration" "post_sheet_url" {
  api_id                    = aws_apigatewayv2_api.aws_api.id
  integration_type          = "AWS_PROXY"
  connection_type           = "INTERNET"
  description               = "Lambda Post Sheet URL Integration"
  integration_method        = "POST"
  integration_uri           = var.lambda_invoke_arn_raw_data_etl
}

resource "aws_lambda_permission" "api_gw_upload_img" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name_upload_img
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.aws_api.execution_arn}/*"
}

resource "aws_lambda_permission" "api_gw_raw_data_etl" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name_raw_data_etl
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.aws_api.execution_arn}/*"
}

resource "aws_apigatewayv2_route" "upload_img" {
  api_id    = aws_apigatewayv2_api.aws_api.id
  route_key = "${var.post_img_route}"
  target    = "integrations/${aws_apigatewayv2_integration.upload_img.id}"
  # authorization_type = "JWT"
  # authorizer_id      = aws_apigatewayv2_authorizer.example.id
  depends_on = [aws_apigatewayv2_integration.upload_img]
}

resource "aws_apigatewayv2_route" "post_sheet_url" {
  api_id    = aws_apigatewayv2_api.aws_api.id
  route_key = "${var.post_raw_data_route}"
  target    = "integrations/${aws_apigatewayv2_integration.post_sheet_url.id}"
  # authorization_type = "JWT"
  # authorizer_id      = aws_apigatewayv2_authorizer.example.id
  depends_on = [aws_apigatewayv2_integration.post_sheet_url]
}

resource "aws_apigatewayv2_stage" "main_stage_route_config" {
  api_id      = aws_apigatewayv2_api.aws_api.id
  name        = var.default_stage
  description = "Default stage for Fiscalismia API"
  default_route_settings {
    throttling_burst_limit = 5    # Max burst of 5 requests
    throttling_rate_limit  = 2.0  # Sustained rate of 2 requests per second
  }
  route_settings {
    route_key             = "${var.post_img_route}"
    throttling_burst_limit = 5
    throttling_rate_limit  = 2.0
  }
  route_settings {
    route_key             = "${var.post_raw_data_route}"
    throttling_burst_limit = 5
    throttling_rate_limit  = 2.0
  }
  auto_deploy = true
  depends_on = [aws_apigatewayv2_route.upload_img, aws_apigatewayv2_route.post_sheet_url]
}

# TODO https://docs.aws.amazon.com/apigateway/latest/developerguide/http-api-jwt-authorizer.html
# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/apigatewayv2_authorizer
# resource "aws_apigatewayv2_authorizer" "example" {
#   api_id                            = aws_apigatewayv2_api.example.id
#   name                              = "jwt-authorizer"
#   authorizer_type                   = "JWT"
#   identity_sources                  = ["$request.header.Authorization"] 
#   authorizer_payload_format_version = "2.0"+
#   jwt_configuration                 = {
#    audience = ["your-client-id"]  # The expected audience of the JWT (e.g., Cognito client ID or your OAuth2 client)
#    issuer   = "https://your-issuer-url"  # The URL of the JWT issuer (e.g., Cognito's identity pool or your OAuth2 provider)
#   }
# }
