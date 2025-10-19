# See https://docs.hetzner.com/cloud/placement-groups/overview
# Spreads multiple instances across separtate physical hardware

# resource "hcloud_placement_group" "unix_vps" {
#   labels = local.default_labels
#   name = "placement-group-${var.server_name}"
#   type = "spread"
# }