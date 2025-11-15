resource "hcloud_primary_ip" "bastion_host_static_ipv4" {
  name              = "bastion-host-static-ipv4"
  datacenter        = var.datacenter
  type              = "ipv4"
  assignee_type     = "server"
  auto_delete       = false
  labels            = var.labels
  delete_protection = true
}
