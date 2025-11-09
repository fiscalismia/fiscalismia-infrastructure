resource "hcloud_server" "unix_vps" {
  labels                     = var.labels
  count                      = var.instance_count
  name                       = "${var.server_name}-${count.index +1}"
  image                      = data.hcloud_image.unix_img.id
  server_type                = var.server_type
  location                   = var.location
  ssh_keys                   = [var.ssh_key_name]
  allow_deprecated_images    = false
  shutdown_before_deletion   = false
  backups                    = false
  firewall_ids               = var.firewall_ids
  rebuild_protection         = var.protect_resource # must be same as delete protection
  delete_protection          = var.protect_resource # must be same as rebuild protection
  keep_disk                  = true
  user_data                  = file("${path.module}/user_data/cloud-config.yml")
  public_net {
    ipv4_enabled = var.is_private ? false : true
    ipv6_enabled = false
  }

  provisioner "local-exec" {
    command = "echo ${self.name} : ${self.ipv4_address} >> server-ips.txt"
  }

}
