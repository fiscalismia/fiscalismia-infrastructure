# Shared Layer for all Infrastructure Python functions
resource "aws_lambda_layer_version" "infrastructure_layer" {
  layer_name                = var.layer_name
  description               = var.layer_description
  s3_bucket                 = var.infrastructure_s3_bucket
  s3_key                    = "${var.infrastructure_s3_prefix}/${var.layer_name}.zip"
  compatible_runtimes       = [var.infrastructure_runtime]
  compatible_architectures  = ["x86_64"]
}