module "ansible_control_node" {
  source            = "./modules/hcloud_server"

  server_name       = "Ansible-Control-Node"
  unix_distro       = "fedora-42"
  server_type       = "cx23"
  ssh_key_name      = hcloud_ssh_key.default.name

  default_labels = merge(
    local.default_labels,
    {
      environment = "development"
    }
  )
}