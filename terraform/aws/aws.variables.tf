variable "region" {
  default = "eu-central-1"
  description = "region for aws resources"
  type = string
}
variable "application_prefix" {
  default = "Fiscalismia"
  description = "prefix for naming conventions of e.g. Lambdas"
  type = string
}
variable "infrastructure_prefix" {
  default = "Infrastructure"
  description = "prefix for naming conventions of e.g. Lambdas"
  type = string
}
variable "ip_whitelist_lambda_processing" {
  default = "0.0.0.0" # Override ONLY IN terraform.tfvars to hide whitelist from git repository
  description = "Comma separated list to allow only specific ips access to Lambda functions. Passed in lambda env vars. Default is allowing all (0.0.0.0)."
  type = string
}
variable "forecasted_budget_notification_email" {
  description = "Email address receiving aws cost budget notifications saved in tfvars"
  type = string
  sensitive   = true
}
################### LAMBDA FUNCTIONS AND LAYERS #########################
variable "lambda_handler_name" {
  default = "index.lambda_handler"
  description = "The default lambda handler used by AWS"
  type = string
}
variable "lambda_function_application_log_level" {
  default = "INFO"
  description = "Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  type = string
}
variable "lambda_function_system_log_level" {
  default = "INFO" # runtime information like START, END, REPORT including metrics such as billedDurationMs and maxMemoryUsedMB
  description = "Valid values: DEBUG, INFO, WARN."
  type = string
}

################### API GATEWAY #########################
variable "default_stage" {
  default = "apigw"
  type = string
  description = "HTTP API can be separated into stages that change the endpoint routes to start with /stage/"
}
variable "post_img_route" {
  default = "/fiscalismia/post/img/invoke_lambda/return_s3_img_url"
  type = string
  description = "http api route for aws. the default stage is prepended."
}
variable "post_raw_data_route" {
  default = "/fiscalismia/post/raw_data_etl/invoke_lambda/return_tsv_file_urls"
  type = string
  description = "http api route to invoke raw data etl lambda. Returns S3 URLS to exported TSV files"
}
################ S3 BUCKETS #############################
variable "s3_bucket_name_prefix" {
  description = "Bucket Name Prefix to use for all buckets"
  type = string
  default = "fiscalismia-"
}
variable "etl_bucket_name" {
  description = "Bucket Name for Raw Data Transformation"
  type = string
  default = "raw-data-etl-storage"
}
variable "image_processing_bucket_name" {
  description = "Bucket Name for Image Downsizing"
  type = string
  default = "image-storage"
}
variable "infrastructure_bucket_name" {
  description = "Bucket Name for Fiscalismia Infrastructure binaries, code and dependencies."
  type = string
  default = "infrastructure"
}
variable "terraform_state_bucket" {
  description = "Created in AWS Console outside of terraform IaC"
  type = string
  default = "hangrybear-tf-backend-state-bucket"
}
################### DNS NAMES ###########################
variable "fqdn" {
  default = "https://fiscalismia.com"
  description = "fully qualified domain name of source webservice for CORS access"
  type = string
}
variable "demo_fqdn" {
  default = "https://demo.fiscalismia.com"
  description = "fully qualified domain name of source webservice for CORS access"
  type = string
}
variable "backend_fqdn" {
  default = "https://backend.fiscalismia.com"
  description = "fully qualified domain name of source webservice for CORS access"
  type = string
}
variable "demo_backend_fqdn" {
  default = "https://backend.demo.fiscalismia.com"
  description = "fully qualified domain name of source webservice for CORS access"
  type = string
}
variable "domain_name" {
  default     = "fiscalismia.com"
  description = "Primary domain name for Route 53 DNS"
  type        = string
}
variable "demo_subdomain" {
  default     = "demo"
  description = "Subdomain for demo environment"
  type        = string
}
variable "backend_subdomain" {
  default     = "backend"
  description = "Subdomain for backend service"
  type        = string
}
variable "demo_backend_subdomains" {
  default     = "backend.demo"
  description = "Subdomain for backend service on demo server"
  type        = string
}
variable "fastapi_subdomain" {
  default     = "fastapi"
  description = "Subdomain for backend service"
  type        = string
}
variable "demo_fastapi_subdomains" {
  default     = "fastapi.demo"
  description = "Subdomain for backend service on demo server"
  type        = string
}
variable "monitoring_subdomain" {
  default     = "monitoring"
  description = "Subdomain for monitoring frontend"
  type        = string
}
