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
  hcloud_fiscalismia_bastion_host_ipv4    = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_bastion_host_ipv4, "127.0.0.1")
  hcloud_fiscalismia_loadbalancer_ipv4    = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_loadbalancer_ipv4, "127.0.0.1")
  hcloud_fiscalismia_nat_gateway_ipv4     = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_nat_gateway_ipv4, "127.0.0.1")
  hcloud_fiscalismia_demo_ipv4            = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_demo_private_ipv4, "127.0.0.1")
  hcloud_fiscalismia_monitoring_ipv4      = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_monitoring_private_ipv4, "127.0.0.1")
  hcloud_fiscalismia_frontend_ipv4        = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_frontend_private_ipv4, "127.0.0.1")
  hcloud_fiscalismia_backend_ipv4         = try(data.terraform_remote_state.hcloud_remote.outputs.fiscalismia_backend_private_ipv4, "127.0.0.1")
  no_ip = "No IP present"
}