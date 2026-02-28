module "route_53_dns" {
  source                                = "./modules/route_53"
  demo_subdomain                        = var.demo_subdomain            # demo frontend
  demo_backend_subdomains               = var.demo_backend_subdomains   # demo backend
  domain_name                           = var.domain_name               # MAIN Frontend
  backend_subdomain                     = var.backend_subdomain         # MAIN Backend
  monitoring_subdomain                  = var.monitoring_subdomain      # Prometheus & Grafana
  loadbalancer_instance_ipv4            = local.hcloud_fiscalismia_loadbalancer_ipv4
}

# Gives Hcloud Servers AWS Access via User Access Keys for e.g. DNS TXT Record verification for TLS Cert Renewal
module "hcloud_iam_access" {
  source                                = "./modules/hcloud_iam_access"
  domain_name                           = var.domain_name
}

# Defines downscoped roles for github actions pipelines running with short-lived STS credentials
module "oidc_sts_pipeline_access" {
  source                                = "./modules/openid_connect"
  github_actions_provider_url           = "https://token.actions.githubusercontent.com"
  infrastructure_s3_bucket              = module.s3_infrastructure_storage.bucket_name
  region                                = var.region
  s3_bucket_name_prefix                 = var.s3_bucket_name_prefix
  terraform_state_bucket                = var.terraform_state_bucket
  application_prefix                    = var.application_prefix
  infrastructure_prefix                 = var.infrastructure_prefix
  github_org                            = "fiscalismia"
  github_lambda_repo                    = "fiscalismia-lambdas"
  github_infrastructure_repo            = "fiscalismia-infrastructure"
  lambda_s3_app_prefix                  = "lambdas/fiscalismia"
  lambda_s3_infra_prefix                = "lambdas/infrastructure"
}

# Fiscalismia Application bucket for persisting uploaded user images downsized via AWS Lambda
module "s3_image_storage" {
  source                                = "./modules/s3"
  bucket_name                           = "${var.s3_bucket_name_prefix}${var.image_processing_bucket_name}"
  fqdn                                  = var.fqdn
  demo_fqdn                             = null  # demo instance doesn't use s3 img storage
  data_infrequent_access                = false # do NOT send to IA
  data_infrequent_access_days           = null
  data_archival                         = false # do NOT archive
  data_archival_days                    = null
  data_expiration                       = false # do NOT delete
  data_expiration_days                  = null
  lambda_execution_role_arns            = [aws_iam_role.lambda_execution_role_app.arn]
}

# Fiscalismia Application bucket acting ETL Repository for Raw Data Transformation using Sheets and TSV files
module "s3_raw_data_etl_storage" {
  source                                = "./modules/s3"
  bucket_name                           = "${var.s3_bucket_name_prefix}${var.etl_bucket_name}"
  fqdn                                  = var.fqdn
  demo_fqdn                             = var.demo_fqdn
  data_infrequent_access                = true  # data is sent to infrequent access
  data_infrequent_access_days           = 30    # after this many days
  data_archival                         = true  # data is sent to glacier
  data_archival_days                    = 90    # after this many days
  data_expiration                       = true  # data is deleted after
  data_expiration_days                  = 365   # this many days
  lambda_execution_role_arns            = [aws_iam_role.lambda_execution_role_app.arn]
}

# Fiscalismia Infrastructure binaries, code and dependencies
module "s3_infrastructure_storage" {
  source                                = "./modules/s3"
  bucket_name                           = "${var.s3_bucket_name_prefix}${var.infrastructure_bucket_name}"
  fqdn                                  = null
  demo_fqdn                             = null
  data_infrequent_access                = true  # data is sent to infrequent access
  data_infrequent_access_days           = 30    # after this many days
  data_archival                         = false # do NOT archive
  data_archival_days                    = null
  data_expiration                       = false # do NOT delete
  data_expiration_days                  = null
  lambda_execution_role_arns            = [aws_iam_role.lambda_execution_role_infra.arn]
}

# endpoint to connect fiscalismia containers (file upload) to lambdas for further processing
module "api_gateway" {
  source                                 = "./modules/api_gateway"
  api_name                               = "Fiscalismia-HTTP-Api-Gateway"
  api_description                        = "Fiscalismia HTTP v2 API Gateway"
  fqdn                                   = var.fqdn
  lambda_function_name_upload_img        = module.lambda_image_processing.function_name
  lambda_invoke_arn_upload_img           = module.lambda_image_processing.invoke_arn
  lambda_function_name_raw_data_etl      = module.lambda_raw_data_etl.function_name
  lambda_invoke_arn_raw_data_etl         = module.lambda_raw_data_etl.invoke_arn
  post_img_route                         = "POST ${var.post_img_route}"
  post_raw_data_route                    = "POST ${var.post_raw_data_route}"
  default_stage                          = var.default_stage
}

module "lambda_image_processing" {
  source                                = "./modules/application_lambda"
  function_name                         = "${var.application_prefix}_ImageProcessing"
  function_description                  = "Lambda for receiving uploaded user images and reducing them in filesize"
  layer_name                            = "${var.application_prefix}_ImageProcessing_NodeJSDependencies"
  layer_description                     = "NodeJS Dependencies for Image Processing Lambda Function"
  lambda_execution_role_arn             = aws_iam_role.lambda_execution_role_app.arn
  lambda_execution_role_name            = aws_iam_role.lambda_execution_role_app.name
  infrastructure_s3_bucket              = module.s3_infrastructure_storage.bucket_name
  handler_name                          = var.lambda_handler_name
  application_log_level                 = var.lambda_function_application_log_level
  system_log_level                      = var.lambda_function_system_log_level
  infrastructure_s3_prefix              = "lambdas/fiscalismia/nodejs"
  runtime_env                           = "nodejs22.x"
  timeout_seconds                       = 10
  memory_size                           = 256
  cloudwatch_log_retention_days         = 365
  s3_lambda_application_bucket          = module.s3_image_storage.bucket_name
  ip_whitelist_lambda_processing        = var.ip_whitelist_lambda_processing
}

module "lambda_raw_data_etl" {
  source                                = "./modules/application_lambda"
  function_name                         = "${var.application_prefix}_RawDataETL"
  function_description                  = "Lambda for fetching google sheets, transforming it into TSV files with S3 persistence, returning s3 object URLs."
  layer_name                            = "${var.application_prefix}_RawDataETL_PythonDependencies"
  layer_description                     = "Python Dependencies for RAW Data ETL Lambda Function"
  lambda_execution_role_arn             = aws_iam_role.lambda_execution_role_app.arn
  lambda_execution_role_name            = aws_iam_role.lambda_execution_role_app.name
  infrastructure_s3_bucket              = module.s3_infrastructure_storage.bucket_name
  handler_name                          = var.lambda_handler_name
  application_log_level                 = var.lambda_function_application_log_level
  system_log_level                      = var.lambda_function_system_log_level
  infrastructure_s3_prefix              = "lambdas/fiscalismia/python"
  runtime_env                           = "python3.13"
  timeout_seconds                       = 20
  memory_size                           = 1024
  cloudwatch_log_retention_days         = 365
  s3_lambda_application_bucket          = module.s3_raw_data_etl_storage.bucket_name
  ip_whitelist_lambda_processing        = var.ip_whitelist_lambda_processing
}

# Collection of multiple lambdas for infrastructure monitoring, alarms and automated teardown
module "infrastructure_lambdas" {
  source                                       = "./modules/infrastructure_lambdas"
  region                                       = var.region
  apigw_route_throttler_name                   = "${var.infrastructure_prefix}_ApiGatewayRouteThrottler"
  notification_message_sender_name             = "${var.infrastructure_prefix}_NotificationMessageSender"
  terraform_destroy_trigger_name               = "${var.infrastructure_prefix}_TerraformDestroyTrigger"
  sandbox_function_testing_name                = "Test_PythonSandbox"
  apigw_route_throttler_description            = "After Cloudwatch Metric Alarm surpasses threshold, Lambda shuts down the API Gateway Routes"
  notification_message_sender_description      = "Generic Notification Messages via Telegram API to Fiscalismia-Messaging Bot"
  terraform_destroy_trigger_description        = "After Actual Cost Budget has been exceeded, triggers a Github Actions pipeline to destroy non-persistent AWS resources"
  sandbox_function_testing_description         = "Testing sandbox for evaluating new functionality and debugging Python Lambdas"

  layer_name                                   = "${var.infrastructure_prefix}_PythonDependencies"
  layer_description                            = "Shared Python Dependencies for Infrastructure Lambdas."
  lambda_execution_role_name                   = aws_iam_role.lambda_execution_role_infra.name
  lambda_execution_role_arn                    = aws_iam_role.lambda_execution_role_infra.arn
  handler_name                                 = var.lambda_handler_name
  application_log_level                        = var.lambda_function_application_log_level
  system_log_level                             = var.lambda_function_system_log_level
  infrastructure_runtime                       = "python3.13"
  cloudwatch_log_retention_days                = 365
  infrastructure_s3_bucket                     = module.s3_infrastructure_storage.bucket_name
  infrastructure_s3_prefix                     = "lambdas/infrastructure/python"
}

module "cost_budget_alarms" {
  source                                = "./modules/cost_budget"
  cost_budget_alarm_total_actual_name   = "TotalBudgetActual-InfrastructureKillswitch"
  cost_budget_alarm_total_forecast_name = "TotalBudgetForecast-EmailNotification"
  sns_topic_arn_budget_limit_exceeded   = module.sns_topics.budget_limit_exceeded_arn
  forecasted_budget_notification_email  = var.forecasted_budget_notification_email
}

module "sns_topics" {
  source                                       = "./modules/sns_topic"
  sns_topic_budget_limit_exceeded_name         = "BudgetLimitExceededAction"
  sns_topic_apigw_route_throttling_name        = "ApiGatewayRouteThrottling"
  sns_topic_notification_message_sending_name  = "NotificationMessageSending"
  sns_topic_sandbox_sns_testing_name           = "SandboxSnsTesting"
  cloudwatch_log_retention_days                = 30
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