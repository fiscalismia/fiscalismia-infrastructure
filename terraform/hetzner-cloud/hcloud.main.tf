module "ansible_control_node" {
  source            = "./modules/hcloud_server/"

  server_name       = "Ansible-Control-Node"
  unix_distro       = "fedora-42"
  server_type       = "cx23" # 3.56€ / Month
  firewall_ids      = [
    hcloud_firewall.ssh_access.id,
    hcloud_firewall.icmp_ping_ingress.id
  ]
  ssh_key_name      = hcloud_ssh_key.infrastructure_orchestration.name

  labels            = local.default_labels
}

module "fiscalismia_demo" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Demo"
  unix_distro       = "fedora-42"
  server_type       = "cx33" # 5.93€/Month
  firewall_ids      = [
    hcloud_firewall.all_egress.id,
    hcloud_firewall.public_http_ingress.id,
    hcloud_firewall.icmp_ping_ingress.id
  ]
  ssh_key_name      = hcloud_ssh_key.demo_instance.name

  labels            = local.default_labels
}