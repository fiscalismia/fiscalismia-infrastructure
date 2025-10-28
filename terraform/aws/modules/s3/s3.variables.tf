variable "bucket_name" {}
variable "bucket_description" {}
variable "fqdn" {}
variable "lambda_execution_role_arns" {}
variable "data_expiration" {
  default = false
  type    = bool
  description = "whether objects are deleted after a certain period"
}
variable "data_archival" {
  default = false
  type    = bool
  description = "whether objects are moved to cheaper storage tiers after a certain period"
}
variable "prevent_destroy" {
  default = true
  type    = bool
  description = "whether s3 bucket is being protected from deletion"
}