#     __   __           __        __  ___    __                __   __  ___
#    /__` /__` |__|    |__)  /\  /__`  |  | /  \ |\ |    |__| /  \ /__`  |
#    .__/ .__/ |  |    |__) /~~\ .__/  |  | \__/ | \|    |  | \__/ .__/  |
#
# Acts as bastion host for access to all instances in private subnet via private IPV4
module "fiscalismia_bastion_host" {
  source            = "./modules/hcloud_server/"

  server_name         = "Fiscalismia-Bastion-Host"
  unix_distro         = var.unix_distro
  location            = var.default_location
  static_public_ip_id = module.bastion_host_static_ip.ip.id
  private_ip_1        = var.fiscalismia_bastion_host_private_ipv4_demo_net
  network_id_1        = hcloud_network.network_private_class_b_demo.id
  private_ip_2        = var.fiscalismia_bastion_host_private_ipv4_production_net
  network_id_2        = hcloud_network.network_private_class_b_production.id
  server_type         = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids        = [
    hcloud_firewall.public_ssh_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
    hcloud_firewall.egress_ssh_to_fiscalismia_instances.id,
  ]
  ssh_key_name        = hcloud_ssh_key.infrastructure_orchestration.name

  labels              = local.default_labels

  depends_on = [
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}

#     __        __          __          ___ ___  __   __           __   __   ___  __   __
#    |__) |  | |__) |    | /  `    |__|  |   |  |__) /__`     /\  /  ` /  ` |__  /__` /__`
#    |    \__/ |__) |___ | \__,    |  |  |   |  |    .__/    /~~\ \__, \__, |___ .__/ .__/
# HAProxy and central ingress for all DNS routes, uses HTTPS pass-through to appropriate endpoints for mTLS
module "fiscalismia_loadbalancer" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-LoadBalancer"
  unix_distro       = var.unix_distro
  location          = var.default_location
  private_ip_1      = var.fiscalismia_loadbalancer_private_ipv4_demo_net
  network_id_1      = hcloud_network.network_private_class_b_demo.id
  private_ip_2      = var.fiscalismia_loadbalancer_private_ipv4_production_net
  network_id_2      = hcloud_network.network_private_class_b_production.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.public_https_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
    hcloud_firewall.egress_https_to_private_subnet_cidr_ranges.id,
    hcloud_firewall.egress_icmp_to_private_subnet_cidr_ranges.id,
  ]
  ssh_key_name      = hcloud_ssh_key.load_balancer_instance.name
  cloud_config_file = "cloud-config.bastion-host.yml"

  labels            = local.default_labels

  depends_on = [
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}

#     __        __          __            ___  ___  __        ___ ___          __   __   ___  __   __
#    |__) |  | |__) |    | /  `    | |\ |  |  |__  |__) |\ | |__   |      /\  /  ` /  ` |__  /__` /__`
#    |    \__/ |__) |___ | \__,    | | \|  |  |___ |  \ | \| |___  |     /~~\ \__, \__, |___ .__/ .__/
module "fiscalismia_nat_gateway" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-NAT-Gateway"
  unix_distro       = var.unix_distro
  location          = var.default_location
  private_ip_1      = var.fiscalismia_nat_gateway_private_ipv4_demo_net
  network_id_1      = hcloud_network.network_private_class_b_demo.id
  private_ip_2      = var.fiscalismia_nat_gateway_private_ipv4_production_net
  network_id_2      = hcloud_network.network_private_class_b_production.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    # hcloud_firewall.egress_all_public.id,
    hcloud_firewall.egress_public_https_icmp_only.id,
    hcloud_firewall.private_ssh_ingress_from_bastion_host.id,
    hcloud_firewall.private_icmp_ping_ingress_from_loadbalancer.id,
  ]
  ssh_key_name      = hcloud_ssh_key.nat_gateway_instance.name
  cloud_config_file = "cloud-config.nat-gateway.yml"

  labels            = local.default_labels

  depends_on = [
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}
