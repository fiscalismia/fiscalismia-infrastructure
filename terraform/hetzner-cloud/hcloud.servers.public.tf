#     __   __           __        __  ___    __                __   __  ___
#    /__` /__` |__|    |__)  /\  /__`  |  | /  \ |\ |    |__| /  \ /__`  |
#    .__/ .__/ |  |    |__) /~~\ .__/  |  | \__/ | \|    |  | \__/ .__/  |
#
# Acts as bastion host for access to all instances in private subnet via private IPV4
module "fiscalismia_bastion_host" {
  source            = "./modules/hcloud_server/"

  server_name         = "Fiscalismia-Bastion-Host"
  image_id            = data.hcloud_image.fedora_image.id
  location            = var.default_location
  static_public_ip_id = module.bastion_host_static_ip.ip.id
  server_type         = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids        = [
    hcloud_firewall.egress_DENY_ALL_public.id,
    hcloud_firewall.public_ssh_ingress.id,
  ]
  ssh_key_name        = hcloud_ssh_key.infrastructure_orchestration.name
  cloud_config        = data.cloudinit_config.bastion_host.rendered

  labels              = local.default_labels

  # first element in the list is main private ip used for routing to e.g. nat gateway for inet access
  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = local.fiscalismia_bastion_host_private_ipv4_production_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = local.fiscalismia_bastion_host_private_ipv4_demo_net
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
    module.bastion_host_static_ip,
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}

#     __        __          __          ___ ___  __   __           __   __   ___  __   __
#    |__) |  | |__) |    | /  `    |__|  |   |  |__) /__`     /\  /  ` /  ` |__  /__` /__`
#    |    \__/ |__) |___ | \__,    |  |  |   |  |    .__/    /~~\ \__, \__, |___ .__/ .__/
# HAProxy and central ingress for all DNS routes, uses HTTPS pass-through to appropriate endpoints for mTLS
module "fiscalismia_loadbalancer" {
  source              = "./modules/hcloud_server/"

  server_name         = "Fiscalismia-LoadBalancer"
  image_id            = data.hcloud_image.fedora_image.id
  location            = var.default_location
  static_public_ip_id = module.loadbalancer_static_ip.ip.id
  server_type         = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids        = [
    hcloud_firewall.egress_DENY_ALL_public.id,
    hcloud_firewall.public_https_ingress.id,
    hcloud_firewall.public_haproxy_stats_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
  ]
  ssh_key_name        = hcloud_ssh_key.load_balancer_instance.name
  cloud_config        = data.cloudinit_config.loadbalancer.rendered

  labels              = local.default_labels

  # first element in the list is main private ip used for routing to e.g. nat gateway for inet access
  networks            = [
    {
      network_id      = hcloud_network.network_private_class_b_production.id
      private_ip      = local.fiscalismia_loadbalancer_private_ipv4_production_net
    },
    {
      network_id      = hcloud_network.network_private_class_b_demo.id
      private_ip      = local.fiscalismia_loadbalancer_private_ipv4_demo_net
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
    module.loadbalancer_static_ip,
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
  image_id          = data.hcloud_image.fedora_image.id
  location          = var.default_location
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.egress_public_http_https_dns_icmp.id,
  ]
  ssh_key_name      = hcloud_ssh_key.nat_gateway_instance.name
  cloud_config      = data.cloudinit_config.nat_gateway.rendered

  labels            = local.default_labels

  # first element in the list is main private ip used for routing to e.g. nat gateway for inet access
  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = local.fiscalismia_nat_gateway_private_ipv4_production_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = local.fiscalismia_nat_gateway_private_ipv4_demo_net
    }
  ]

  depends_on = [
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}

# Dedicated Security Hardening Evaluation Instance with no public ingress but all open Private Ports for network portscans
module "network_sentinel" {
  source            = "./modules/hcloud_server/"

  server_name       = "Network-Sentinel"
  image_id          = data.hcloud_image.fedora_image.id
  location          = var.default_location
  # CPU Performance Optimized
  server_type       = "cpx32" # "cpx22" 7.72€ / Month | "cpx33" 13.03€/Month
  firewall_ids      = [
    hcloud_firewall.egress_public_http_https_dns_icmp.id,
  ]
  ssh_key_name      = hcloud_ssh_key.infrastructure_orchestration.name
  cloud_config      = data.cloudinit_config.network_sentinel.rendered

  labels            = local.default_labels

  networks          = [
    {
      network_id    = hcloud_network.network_private_class_b_production.id
      private_ip    = local.network_sentinel_private_ipv4_production_net
    },
    {
      network_id    = hcloud_network.network_private_class_b_demo.id
      private_ip    = local.network_sentinel_private_ipv4_demo_net
    }
  ]

  depends_on = [
    module.fiscalismia_nat_gateway,
    hcloud_network.network_private_class_b_demo,
    hcloud_network.network_private_class_b_production,
  ]
}