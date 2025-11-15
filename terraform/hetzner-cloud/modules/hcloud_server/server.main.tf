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
  user_data                  = file("${path.module}/user_data/${var.cloud_config_file}")

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

  dynamic "network" {
    for_each = compact([
      var.network_id_1 != null ?
        jsonencode({
          id = var.network_id_1
          ip = var.private_ip_1
        })
        : null,
        var.network_id_2 != null ?
        jsonencode({
          id = var.network_id_2
          ip = var.private_ip_2
        })
        : null
      ]
    )

    content {
      network_id = jsondecode(network.value).id
      ip         = jsondecode(network.value).ip
    }
  }

  # prevents known race condition bug in hetzner cloud module
  # Hetzner does not guarantee ordering of the private_networks list
  # Sometimes returns incomplete interface lists for a few seconds right after VM creation
  # so when adding two network blocks, the apply stage diverts from the plan stage
  lifecycle {
    ignore_changes = [ network ]
  }

}
