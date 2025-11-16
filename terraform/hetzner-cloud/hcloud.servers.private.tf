#     __   __              ___  ___          ___ ___       __   __           __   ___  __        ___  __   __
#    |__) |__) | \  /  /\   |  |__     |\ | |__   |  |  | /  \ |__) |__/    /__` |__  |__) \  / |__  |__) /__`
#    |    |  \ |  \/  /~~\  |  |___    | \| |___  |  |/\| \__/ |  \ |  \    .__/ |___ |  \  \/  |___ |  \ .__/

# Demo Server running a local database and local image storage for isolated multi-user tests
module "fiscalismia_demo" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Demo"
  is_private        = true
  unix_distro       = var.unix_distro
  location          = var.default_location
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = null # not allowed for private instances without public ip
  ssh_key_name      = hcloud_ssh_key.demo_instance.name
  cloud_config      = data.cloudinit_config.demo_instance.rendered

  labels            = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = var.fiscalismia_demo_private_ipv4
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
    hcloud_network.network_private_class_b_demo,
  ]
}

# Prometheus and Graphana Monitoring Server for health and traffic metrics of the entire Infrastructure
module "fiscalismia_monitoring" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Monitoring"
  is_private        = true
  unix_distro       = var.unix_distro
  location          = var.default_location
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = null # not allowed for private instances without public ip
  ssh_key_name      = hcloud_ssh_key.monitoring_instance.name
  cloud_config      = data.cloudinit_config.production_instances.rendered

  labels            = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = var.fiscalismia_monitoring_private_ipv4
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
    hcloud_network.network_private_class_b_production,
  ]
}