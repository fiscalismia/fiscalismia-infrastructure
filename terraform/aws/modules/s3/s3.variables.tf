variable "bucket_name" {}
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
variable "versioning" {
  default = false
  type    = bool
  description = "whether buckets are versioned to retain history."
}