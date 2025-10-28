module "route_53_dns" {
  source                                = "./modules/route_53"
  domain_name                           = "fiscalismia.com"
  demo_subdomain                        = "demo"
  backend_subdomain                     = "backend"
  resource_prefix                       = "fiscalismia"
  backend_instance_ipv4                 = var.backend_instance_ipv4
  demo_instance_ipv4                    = var.demo_instance_ipv4
  frontend_instance_ipv4                = var.frontend_instance_ipv4
}

# S3 bucket for persisting uploaded user images
module "s3_image_storage" {
  source                                = "./modules/s3"
  bucket_name                           = var.image_processing_bucket_name
  bucket_description                    = "Fiscalismia Image Upload Storage"
  fqdn                                  = var.fqdn
  data_expiration                       = false
  data_archival                         = false
  responsible_lambda_functions          = [module.lambda_image_processing.lambda_role_arn]
}

# S3 bucket for ETL on Google Sheets/TSV file transformations
module "s3_raw_data_etl_storage" {
  source                                = "./modules/s3"
  bucket_name                           = var.etl_bucket_name
  bucket_description                    = "Fiscalismia ETL Repository for Raw Data Transformation for PSQL"
  fqdn                                  = var.fqdn
  data_expiration                       = true
  data_archival                         = true
  responsible_lambda_functions          = [module.lambda_raw_data_etl.lambda_role_arn]
}

# endpoint to connect fiscalismia containers (file upload) to lambdas for further processing
module "api_gateway" {
source                                  = "./modules/api_gateway"
api_name                                = "Fiscalismia-HTTP-Api-Gateway"
api_description                         = "Fiscalismia HTTP v2 API Gateway"
fqdn                                    = var.fqdn
lambda_function_name_upload_img         = module.lambda_image_processing.function_name
lambda_invoke_arn_upload_img            = module.lambda_image_processing.invoke_arn
lambda_function_name_raw_data_etl       = module.lambda_raw_data_etl.function_name
lambda_invoke_arn_raw_data_etl          = module.lambda_raw_data_etl.invoke_arn
post_img_route                          = "POST ${var.post_img_route}"
post_raw_data_route                     = "POST ${var.post_raw_data_route}"
default_stage                           = var.default_stage
}

# Lambda for receiving uploaded user images and reducing them in filesize
module "lambda_image_processing" {
  source                                = "./modules/lambda"
  function_purpose                      = "image_processing"
  layer_description                     = "NodeJS Dependencies for Image Processing Lambda Function"
  runtime_env                           = "nodejs22.x"
  layer_docker_img                      = "public.ecr.aws/lambda/nodejs:22.2024.11.22.14-x86_64"
  timeout_seconds                       = 5
  memory_size                           = 256
  layer_name                            = "${var.service_name}-image-processing-nodejs-layer"
  s3_bucket_name                        = var.image_processing_bucket_name
  service_name                          = var.service_name
  ip_whitelist_lambda_processing        = var.ip_whitelist_lambda_processing
  secret_api_key                        = var.secret_api_key
}

# Lambda for receiving google sheets/tsv files and transforming them into queries to fiscalismia rest api
module "lambda_raw_data_etl" {
  source                                = "./modules/lambda"
  function_purpose                      = "raw_data_etl"
  layer_description                     = "Python Dependencies for RAW Data ETL Lambda Function"
  runtime_env                           = "python3.13"
  layer_docker_img                      = "public.ecr.aws/lambda/python:3.13.2024.11.22.15-x86_64"
  timeout_seconds                       = 15
  memory_size                           = 512
  layer_name                            = "${var.service_name}-raw-data-etl-python-layer"
  s3_bucket_name                        = var.etl_bucket_name
  service_name                          = var.service_name
  ip_whitelist_lambda_processing        = var.ip_whitelist_lambda_processing
  secret_api_key                        = var.secret_api_key
}

module "cost_budget_alarms" {
  source                                = "./modules/cost_budget"
  cost_budget_alarm_total_actual_name   = "TotalBudgetActual-InfrastructureKillswitch"
  cost_budget_alarm_total_forecast_name = "TotalBudgetForecast-EmailNotification"
  sns_topic_arn_budget_limit_exceeded   = module.sns_topics.budget_limit_exceeded_arn
  forecasted_budget_notification_email  = var.forecasted_budget_notification_email
}

module "infrastructure_lambdas" {
  source                                       = "./modules/infrastructure_lambdas"
}

module "sns_topics" {
  source                                       = "./modules/sns_topic"
  sns_topic_budget_limit_exceeded_name         = "BudgetLimitExceededAction" # AWS Budgets only support standard sns topics
  sns_topic_apigw_route_throttling_name        = "ApiGatewayRouteThrottling.fifo"
  sns_topic_notification_message_sending_name  = "NotificationMessageSending.fifo"
  apigw_route_throttler_lambda_arn             = module.infrastructure_lambdas.apigw_route_throttler_arn
  notification_message_sender_lambda_arn       = module.infrastructure_lambdas.notification_message_sender_arn
  terraform_module_destroyer_lambda_arn        = module.infrastructure_lambdas.terraform_module_destroyer_arn
}

module "cloudwatch_metric_alarms" {
  source                                               = "./modules/cloudwatch_metrics"
  sns_topic_arn_apigw_route_throttling                 = module.sns_topics.apigw_route_throttling_arn

  api_gateway_id                                       = module.api_gateway.id
  api_gateway_stage                                    = module.api_gateway.stage
  post_img_route                                       = "POST ${var.post_img_route}"
  post_raw_data_route                                  = "POST ${var.post_raw_data_route}"

  apigw_count_exceeded_post_img_route_name             = "ApiGatewayCountExceeded-PostImgRoute"
  apigw_count_exceeded_post_img_route_description      = "Tracks Count for public API Gateway Route for Image Upload from Frontend"
  apigw_count_exceeded_post_img_route_threshold        = 30

  apigw_count_exceeded_post_raw_data_route_name        = "ApiGatewayCountExceeded-RawDataEtlRoute"
  apigw_count_exceeded_post_raw_data_route_description = "Tracks Count for public API Gateway Route for Admin ETL PSQL Process"
  apigw_count_exceeded_post_raw_data_route_threshold   = 30
}