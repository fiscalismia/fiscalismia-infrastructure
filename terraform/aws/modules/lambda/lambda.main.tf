resource "aws_iam_role" "lambda_execution_role" {
  name = "LambdaExecutionRole_${var.function_purpose}"
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

resource "aws_iam_role_policy_attachment" "execute_lambda_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "archive_file" "create_payload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/payload/${var.function_purpose}/"
  output_path = "${path.module}/payload/${var.function_purpose}/payload.zip"
}

resource "aws_lambda_function" "api_gw_func" {
  function_name            = "${var.service_name}_${var.function_purpose}"
  filename                 = "${path.module}/payload/${var.function_purpose}/payload.zip"
  role                     = aws_iam_role.lambda_execution_role.arn
  handler                  = "index.handler"
  timeout                  = var.timeout_seconds
  runtime                  = var.runtime_env
  memory_size              = var.memory_size
  depends_on               = [aws_iam_role_policy_attachment.execute_lambda_policy]

  environment {
    variables = {
      IP_WHITELIST = "${var.ip_whitelist_lambda_processing}"
      API_KEY = "${var.secret_api_key}"
    }
  }
  layers = [
    aws_lambda_layer_version.dependency_layer.arn
  ]
  # to always recreate the lambda in case payload has been updated
  source_code_hash         = filebase64sha256("${path.module}/payload/${var.function_purpose}/payload.zip")
}
