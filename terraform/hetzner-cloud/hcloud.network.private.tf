# RFC 1918 defines three private IP CIDR Ranges which will never
# be assigned as public IPs and cannot be routed to from the public internet
# Class A Block	10.0.0.0 – 10.255.255.255	10.0.0.0/8	16,777,216
# Class B Block	172.16.0.0 – 172.31.255.255	172.16.0.0/12	1,048,576
# Class C Block	192.168.0.0 – 192.168.255.255	192.168.0.0/16	65,536
resource "hcloud_network" "fiscalismia_private_class_b" {
  labels                    = local.default_labels
  name                      = "fiscalismia-private-network"
  ip_range                  = var.network_private_class_b
  expose_routes_to_vswitch  = false
}
# Subnet 1 for strictly private instances not reachable from the public internet
resource "hcloud_network_subnet" "fiscalismia_private_class_b_1" {
  type         = "cloud"
  network_id   = hcloud_network.fiscalismia_private_class_b.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_1_cidr
}
# Subnet 2 to assign my instances reachable from the public internet their private IPV4s
resource "hcloud_network_subnet" "fiscalismia_private_class_b_2" {
  type         = "cloud"
  network_id   = hcloud_network.fiscalismia_private_class_b.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_2_cidr
}