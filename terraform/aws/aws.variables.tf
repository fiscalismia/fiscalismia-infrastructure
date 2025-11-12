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
variable "test_sheet_url" {
  default = ""  # Override ONLY IN terraform.tfvars to hide google sheets link from git repo
  description = "sheet url for testing rest api raw etl endpoint"
  type = string
}
################### LAMBDA FUNCTIONS AND LAYERS #########################
variable "lambda_handler_name" {
  default = "index.lambda_handler"
  description = "The default lambda handler used by AWS"
  type = string
}
variable "lambda_function_application_log_level" {
  default = "DEBUG"
  description = "Valid values: TRACE, DEBUG, INFO, WARN, ERROR, FATAL."
  type = string
}
variable "lambda_function_system_log_level" {
  default = "DEBUG"
  description = "Valid values: DEBUG, INFO, WARN."
  type = string
}

################### API GATEWAY #########################
variable "default_stage" {
  default = "api"
  type = string
  description = "HTTP API can be separated into stages that change the endpoint routes to start with /stage/"
}
variable "post_img_route" {
  default = "/fiscalismia/post/img/invoke_lambda/return_s3_img_url"
  type = string
  description = "http api route for aws. the default stage is prepended."
}
variable "post_raw_data_route" {
  default = "/fiscalismia/post/sheet_url/invoke_lambda/return_tsv_file_urls"
  type = string
  description = "http api route for google sheets url post to trigger lambda etl and s3 storage. Returns S3 URLS to exported TSV files"
}
variable "secret_api_key" {
  default = ""  # Override ONLY IN terraform.tfvars to hide whitelist from git repository
  description = "API KEY to allow lambda processing. Passed in lambda env vars."
  type = string
  sensitive   = true
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
variable "monitoring_subdomain" {
  default     = "monitoring"
  description = "Subdomain for monitoring frontend"
  type        = string
}
