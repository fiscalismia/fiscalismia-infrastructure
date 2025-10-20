variable "bucket_name" {}
variable "bucket_description" {}
variable "fqdn" {}
variable "responsible_lambda_functions" {}
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