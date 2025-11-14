#     __   __              ___  ___          ___ ___       __   __           __   ___  __        ___  __   __
#    |__) |__) | \  /  /\   |  |__     |\ | |__   |  |  | /  \ |__) |__/    /__` |__  |__) \  / |__  |__) /__`
#    |    |  \ |  \/  /~~\  |  |___    | \| |___  |  |/\| \__/ |  \ |  \    .__/ |___ |  \  \/  |___ |  \ .__/

# Prometheus and Graphana Monitoring Server for health and traffic metrics of the entire Infrastructure
module "fiscalismia_monitoring" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Monitoring"
  is_private        = true
  unix_distro       = var.unix_distro
  location          = var.default_location
  private_ipv4      = var.fiscalismia_monitoring_private_ipv4
  network_id        = hcloud_network.fiscalismia_private_class_b.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.egress_all_public.id,
    hcloud_firewall.private_ssh_ingress_from_bastion_host.id,
    hcloud_firewall.private_icmp_ping_ingress_from_loadbalancer.id,
    hcloud_firewall.private_https_ingress_from_loadbalancer.id,
  ]
  ssh_key_name      = hcloud_ssh_key.monitoring_instance.name

  labels            = local.default_labels

  depends_on = [
      module.fiscalismia_loadbalancer
  ]
}
# Demo Server running a local database and local image storage for isolated multi-user tests
module "fiscalismia_demo" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Demo"
  is_private        = true
  unix_distro       = var.unix_distro
  location          = var.default_location
  private_ipv4      = var.fiscalismia_demo_private_ipv4
  network_id        = hcloud_network.fiscalismia_private_class_b.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.egress_all_public.id,
    hcloud_firewall.private_ssh_ingress_from_bastion_host.id,
    hcloud_firewall.private_icmp_ping_ingress_from_loadbalancer.id,
    hcloud_firewall.private_https_ingress_from_loadbalancer.id,
  ]
  ssh_key_name      = hcloud_ssh_key.demo_instance.name

  labels            = local.default_labels

  depends_on = [
      module.fiscalismia_loadbalancer
  ]
}
