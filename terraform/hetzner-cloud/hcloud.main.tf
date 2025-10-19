module "ansible_control_node" {
  source            = "./modules/hcloud_server/"

  server_name       = "Ansible-Control-Node"
  unix_distro       = "fedora-42"
  server_type       = "cx23" # 3.56€ / Month
  ssh_key_name      = hcloud_ssh_key.infrastructure_orchestration.name

  labels = merge(
    local.default_labels,
    {
      environment = "development"
    }
  )
}

module "fiscalismia_demo" {
  source            = "./modules/hcloud_server/"

  server_name       = "Fiscalismia-Demo"
  unix_distro       = "fedora-42"
  server_type       = "cx33" # 5.93€/Month
  ssh_key_name      = hcloud_ssh_key.demo_instance.name

  labels = merge(
    local.default_labels,
    {
      environment = "development"
    }
  )
}