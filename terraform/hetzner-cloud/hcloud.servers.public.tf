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
  server_type         = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids        = [
    hcloud_firewall.egress_DENY_ALL_public.id,
    hcloud_firewall.public_ssh_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
  ]
  ssh_key_name        = hcloud_ssh_key.infrastructure_orchestration.name
  cloud_config        = data.cloudinit_config.bastion_host.rendered

  labels              = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = var.fiscalismia_bastion_host_private_ipv4_demo_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = var.fiscalismia_bastion_host_private_ipv4_production_net
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
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
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.egress_DENY_ALL_public.id,
    hcloud_firewall.public_https_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
  ]
  ssh_key_name      = hcloud_ssh_key.load_balancer_instance.name
  cloud_config      = data.cloudinit_config.sandbox.rendered

  labels            = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = var.fiscalismia_loadbalancer_private_ipv4_demo_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = var.fiscalismia_loadbalancer_private_ipv4_production_net
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
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
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.egress_public_https_icmp_only.id,
  ]
  ssh_key_name      = hcloud_ssh_key.nat_gateway_instance.name
  cloud_config      = data.cloudinit_config.nat_gateway.rendered

  labels            = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = var.fiscalismia_nat_gateway_private_ipv4_demo_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = var.fiscalismia_nat_gateway_private_ipv4_production_net
    }
  ]

  depends_on = [
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}
