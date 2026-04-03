variable "bucket_name" {}
variable "fqdn" {}
variable "demo_fqdn" {}
variable "lambda_execution_role_arns" {
  description = "ARNs of Lambda execution roles that need S3 access"
  type        = list(string)
  default     = []
}
variable "data_infrequent_access" {
  default     = false
  type        = bool
  description = "whether objects are moved to STANDARD_IA storage class"
}
variable "data_infrequent_access_days" {
  type        = number
  description = "number of days before objects are moved to STANDARD_IA"
}
variable "data_archival" {
  default     = false
  type        = bool
  description = "whether objects are moved to GLACIER storage classes"
}
variable "data_archival_days" {
  type        = number
  description = "number of days before objects are moved to GLACIER_IR (GLACIER is +60 days after)"
}
variable "data_expiration" {
  default     = false
  type        = bool
  description = "whether objects are permanently deleted after a certain period"
}
variable "data_expiration_days" {
  type        = number
  description = "number of days before objects are permanently deleted"
}
variable "versioning" {
  default = false
  type    = bool
  description = "whether buckets are versioned to retain history."
}
variable "apply_cors_rules" {
  description = "Whether to apply CORS rules to the S3 bucket"
  type        = bool
  default     = false
}