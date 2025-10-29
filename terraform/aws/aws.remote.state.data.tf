data "terraform_remote_state" "hcloud_remote" {
  backend = "s3"
  config = {
    bucket = "hangrybear-tf-backend-state-bucket"
    key = "fiscalismia-infrastructure/hcloud/state.tfstate"
    region = "eu-central-1"
  }
}

# output "all_hcloud_outputs" {
#   value = "${data.terraform_remote_state.hcloud_remote.outputs}"
# }

locals {
  hcloud_fiscalismia_demo_ipv4      = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_demo_server_1_ipv4, "127.0.0.1")
  hcloud_fiscalismia_frontend_ipv4  = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_frontend_server_1_ipv4, "127.0.0.1")
  hcloud_fiscalismia_backend_ipv4   = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_backend_server_1_ipv4, "127.0.0.1")
  no_ip = "No IP present"
}

output "hcloud_serverlist" {
  value = join("\n", [
    format("%-30s %s", "${var.demo_subdomain}.${var.domain_name}:", local.hcloud_fiscalismia_demo_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_demo_ipv4 : local.no_ip),
    format("%-30s %s", "${var.domain_name}:", local.hcloud_fiscalismia_frontend_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_frontend_ipv4 : local.no_ip),
    format("%-30s %s", "${var.backend_subdomain}.${var.domain_name}:", local.hcloud_fiscalismia_backend_ipv4 != "127.0.0.1" ? local.hcloud_fiscalismia_backend_ipv4 : local.no_ip),
  ])
}