resource "hcloud_primary_ip" "static_ipv4" {
  name              = var.primary_ip_name
  datacenter        = var.datacenter
  type              = "ipv4"
  assignee_type     = "server"
  auto_delete       = false
  labels            = var.labels
  delete_protection = true
}
