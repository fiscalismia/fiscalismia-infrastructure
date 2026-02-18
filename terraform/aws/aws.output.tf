output "tls_certificate" {
  description = "TLS Cert for root domain including all subdomains via *.domain.top_level_domain"
  value = module.route_53_dns.tls_certificate
  sensitive    = true
}
output "http_aws_api_endpoint" {
  description = "The http api endpoint"
  value = module.api_gateway.aws_api.api_endpoint
  sensitive    = true
}
output "http_aws_api_arn" {
  description = "The http api arn"
  value = module.api_gateway.aws_api.arn
  sensitive    = true
}
output "http_aws_api_execution_arn" {
  description = "The http api execution arn"
  value = module.api_gateway.aws_api.execution_arn
  sensitive    = true
}
output "route_upload_img" {
  value = "${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_img_route}"
  sensitive    = true
}
output "route_post_etl_raw_data" {
  value = "${module.api_gateway.aws_api.api_endpoint}/${var.default_stage}${var.post_raw_data_route}"
  sensitive    = true
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
