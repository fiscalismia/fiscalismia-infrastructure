data "archive_file" "create_payload_zip" {
  type        = "zip"
  source_dir  = "${path.module}/payload/${var.function_purpose}/"
  output_path = "${path.module}/payload/${var.function_purpose}/payload.zip"
}