#     __   __           __        __  ___    __                __   __  ___
#    /__` /__` |__|    |__)  /\  /__`  |  | /  \ |\ |    |__| /  \ /__`  |
#    .__/ .__/ |  |    |__) /~~\ .__/  |  | \__/ | \|    |  | \__/ .__/  |
#
# Acts as bastion host and ansible deployment/provisioning server
module "ansible_control_node" {
  source            = "./modules/hcloud_server/"

  server_name       = "Ansible-Control-Node"
  unix_distro       = var.unix_distro
  location          = var.default_location
  private_ipv4      = var.ansible_control_node_private_ipv4
  network_id        = hcloud_network.fiscalismia_private_class_b.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.public_ssh_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
    hcloud_firewall.egress_ssh_to_private_subnet_cidr_ranges.id,
    hcloud_firewall.egress_all_public.id
  ]
  ssh_key_name      = hcloud_ssh_key.infrastructure_orchestration.name

  labels            = local.default_labels
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
  private_ipv4      = var.fiscalismia_loadbalancer_private_ipv4
  network_id        = hcloud_network.fiscalismia_private_class_b.id
  server_type       = "cx23" # 3.56€ / Month | "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.public_https_ingress.id,
    hcloud_firewall.public_icmp_ping_ingress.id,
    hcloud_firewall.egress_https_to_private_subnet_cidr_ranges.id,
    hcloud_firewall.egress_icmp_to_private_subnet_cidr_ranges.id,
  ]
  ssh_key_name      = hcloud_ssh_key.load_balancer_instance.name

  labels            = local.default_labels
}