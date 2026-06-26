resource "hcloud_primary_ip" "static_ipv4" {
  name              = var.primary_ip_name
  location          = var.location
  type              = "ipv4"
  auto_delete       = false
  labels            = var.labels
  delete_protection = true
}
