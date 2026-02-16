##################### LAMBDA EXECUTION ROLES APPLICATION ####################
resource "aws_iam_role" "lambda_execution_role_app" {
  name = "LambdaExecutionRole_FiscalismiaWebservice"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_app" {
  role       = aws_iam_role.lambda_execution_role_app.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "lambda_role_app_secretsmgr_access" {
  role       = aws_iam_role.lambda_execution_role_app.name
  policy_arn = aws_iam_policy.lambda_query_secrets_manager_access.arn
}

resource "aws_iam_policy" "lambda_query_secrets_manager_access" {
  name        = "ApplicationLambda_SecretsManagerAccess"
  path        = "/"
  description = "IAM policy for allowing Application Lambdas Access to scoped down Secrets"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
        ]
        Resource = [
          "arn:aws:secretsmanager:eu-central-1:010928217051:secret:/google/sheets/fiscalismia-datasource-url-k38OGm",
          "arn:aws:secretsmanager:eu-central-1:010928217051:secret:/api/fiscalismia/API_GW_SECRET_KEY-4AjIFN"
        ]
      }
    ]
  })
}

# CloudWatch Logs policy
resource "aws_iam_policy" "lambda_cloudwatch_logging_app" {
  name        = "CloudwatchLogging-ApplicationPolicy"
  path        = "/"
  description = "IAM policy for logging from Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_cloudwatch_logging_app" {
  role       = aws_iam_role.lambda_execution_role_app.name
  policy_arn = aws_iam_policy.lambda_cloudwatch_logging_app.arn
}

##################### LAMBDA EXECUTION ROLES INFRASTRUCTURE ####################
resource "aws_iam_role" "lambda_execution_role_infra" {
  name = "LambdaExecutionRole_Infrastructure"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Sid    = ""
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_role_infra" {
  role       = aws_iam_role.lambda_execution_role_infra.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "apigw_route_throttler_policy" {
  name = "ApiGatewayRouteThrottlerPolicy"
  role = aws_iam_role.lambda_execution_role_infra.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "apigateway:PATCH",
          "apigateway:PUT",
          "apigateway:GET",
          "apigateway:POST"
        ]
        Resource = "arn:aws:apigateway:${var.region}::/apis/*/routes/*/routesettings"
      },
      {
        Effect = "Allow"
        Action = [
          "apigateway:GET"
        ]
        Resource = "arn:aws:apigateway:${var.region}::/apis/*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = module.sns_topics.notification_message_sending_arn
      }
    ]
  })
}

# Terraform Destroy Trigger needs Secrets Manager access
resource "aws_iam_role_policy" "terraform_destroy_trigger_policy" {
  name = "TerraformDestroyTriggerPolicy"
  role = aws_iam_role.lambda_execution_role_infra.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = "arn:aws:secretsmanager:${var.region}:*:secret:terraform-destroyer-trigger-token*"
      },
      {
        Effect = "Allow"
        Action = [
          "sns:Publish"
        ]
        Resource = module.sns_topics.notification_message_sending_arn
      }
    ]
  })
}