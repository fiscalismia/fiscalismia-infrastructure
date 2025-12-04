output "tls_certificate" {
  description = "TLS Cert for root domain including all subdomains via *.domain.top_level_domain"
  value = module.route_53_dns.tls_certificate
}
output "http_aws_api_endpoint" {
  description = "The http api endpoint"
  value = module.api_gateway.aws_api.api_endpoint
}
output "http_aws_api_arn" {
  description = "The http api arn"
  value = module.api_gateway.aws_api.arn
}
output "http_aws_api_execution_arn" {
  description = "The http api execution arn"
  value = module.api_gateway.aws_api.execution_arn
}
output "route_upload_img" {
  value = "${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_img_route}"
}
output "route_post_sheet_url" {
  value = "${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_raw_data_route}"
}

output "invoke_application_lambdas" {
  description = "aws cli invoke command to test the lambda function for uploading images"
  value = <<EOT
##### INVOKE UPLOAD IMG LAMBDA
aws lambda invoke --function-name ${module.lambda_image_processing.function_name} /dev/stdout && echo "" && \
  aws lambda invoke --function-name ${module.lambda_image_processing.function_name} --log-type Tail /dev/null | jq -r '.LogResult' | base64 --decode

##### INVOKE RAW DATA ETL LAMBDA
aws lambda invoke --function-name ${module.lambda_raw_data_etl.function_name} \
  --payload '${jsonencode({key1 = "cli-test-value", sheet_url = "https://docs.google.com/spreadsheets/d/e/2PACX-1vSVcmgixKaP9LC-rrqS4D2rojIz48KwKA8QBmJloX1h7f8BkUloVuiw19eR2U5WvVT4InYgnPunUo49/pub?output=xlsx"})}' \
  --cli-binary-format raw-in-base64-out /dev/stdout
EOT
}

output "query_api_gateway_routes" {
  description = "Curl API Gateway Endpoints with Secret Key."
  value = <<EOT
##### CURL ENDPOINT WITH BASE ENCODED IMAGE
bash modules/application_lambda/scripts/curl-api-img-upload.sh ${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_img_route}

# WARNING: Replace with actual secret api key
bash modules/application_lambda/scripts/curl-api-sheet-url.sh [tfvars.secret_api_key] ${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_raw_data_route} [tfvars.test_sheet_url]
EOT
}
output "hcloud_dns_renewal_access_key" {
  description  = "Access Key ID for HCLOUD Instances for DNS TXT Record Verification"
  value        =  module.hcloud_iam_access.access_key_id
  sensitive    = true
}
output "hcloud_dns_renewal_secret_key" {
  description  = "Secret Access Key for HCLOUD Instances for DNS TXT Record Verification"
  value        =  module.hcloud_iam_access.secret_key
  sensitive    = true
}

output "hcloud_serverlist" {
  value = join("\n", [
    "",
    "############ PUBLIC NETWORK INTERFACES ###################",
    format("%-40s %s", "Fiscalismia-Bastion-Host:", local.hcloud_fiscalismia_bastion_host_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_bastion_host_ipv4 : local.no_ip),
    format("%-40s %s", "Fiscalismia-Loadbalancer:", local.hcloud_fiscalismia_loadbalancer_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_loadbalancer_ipv4 : local.no_ip),
    format("%-40s %s", "Fiscalismia-Nat-Gateway:", local.hcloud_fiscalismia_nat_gateway_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_nat_gateway_ipv4 : local.no_ip),
    "",
    "############ PRIVATE ROUTING VIA LOADBALANCER ############",
    format("%-40s %s", "https://${var.demo_subdomain}.${var.domain_name} ->", local.hcloud_fiscalismia_demo_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_demo_ipv4 : local.no_ip),
    format("%-40s %s", "https://${var.demo_backend_subdomains}.${var.domain_name} ->", local.hcloud_fiscalismia_demo_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_demo_ipv4 : local.no_ip),
    format("%-40s %s", "https://${var.monitoring_subdomain}.${var.domain_name} ->", local.hcloud_fiscalismia_monitoring_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_monitoring_ipv4 : local.no_ip),
    format("%-40s %s", "https://${var.domain_name} ->", local.hcloud_fiscalismia_frontend_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_frontend_ipv4 : local.no_ip),
    format("%-40s %s", "https://${var.backend_subdomain}.${var.domain_name} ->", local.hcloud_fiscalismia_backend_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_backend_ipv4 : local.no_ip),
    "",
  ])
}
