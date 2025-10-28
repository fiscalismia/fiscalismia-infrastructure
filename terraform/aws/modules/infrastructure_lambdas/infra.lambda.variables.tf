variable "lambda_execution_role_name" {}
variable "lambda_execution_role_arn" {}
variable "infrastructure_runtime" {}
variable "infrastructure_s3_bucket" {}
variable "infrastructure_s3_prefix" {}
variable "region" {}
variable "cloudwatch_log_retention_days" {
  type = number
}