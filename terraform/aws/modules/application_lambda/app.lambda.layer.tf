resource "aws_lambda_layer_version" "dependency_layer" {
  layer_name                = var.layer_name
  description               = var.layer_description
  s3_bucket                 = var.infrastructure_s3_bucket
  s3_key                    = "${var.infrastructure_s3_prefix}/${var.layer_name}.zip"
  compatible_runtimes       = [var.runtime_env]
  compatible_architectures  = ["x86_64"]
  # depends_on              = [time_sleep.wait_for_layer_creation]
}

##### INFO: Obsolete. For documentation purposes. #####
# This pipeline used to pack the layer and function code directly via shell invocations of aws ecr docker lambda containers
# resource "null_resource" "create_dependency_layer" {
#   provisioner "local-exec" {
#     interpreter = ["/bin/bash", "-c"]
#     working_dir = "${path.module}"
#     command = "bash scripts/create_${var.function_purpose}_layer.sh ${var.runtime_env} ${var.layer_docker_img}"
#   }
#   triggers = {
#     always_trigger = timestamp()
#   }
# }

# resource "time_sleep" "wait_for_layer_creation" {
#   depends_on = [null_resource.create_dependency_layer]
#   create_duration = "5s"
# }