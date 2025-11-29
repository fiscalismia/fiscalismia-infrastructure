resource "hcloud_server" "unix_vps" {
  labels                     = var.labels
  count                      = var.instance_count
  name                       = "${var.server_name}" # -${count.index +1}
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
  user_data                  = var.cloud_config

  # multiple new images per day. Annoying.
  lifecycle {
    ignore_changes = [
        image
    ]
  }
  # public network with static ip
  dynamic "public_net" {
    for_each = var.static_public_ip_id != null ? [1] : []
    content {
      ipv4_enabled = var.is_private ? false : true
      ipv4         = var.static_public_ip_id
      ipv6_enabled = false
    }
  }

  # public network without static ip
  dynamic "public_net" {
    for_each = var.static_public_ip_id == null ? [1] : []
    content {
      ipv4_enabled = var.is_private ? false : true
      ipv6_enabled = false
    }
  }

  # list of 1-3 private network blocks to attach the server to
  dynamic "network" {
    for_each = var.networks
    content {
      network_id = network.value.network_id
      ip         = network.value.private_ip
    }
  }

}
