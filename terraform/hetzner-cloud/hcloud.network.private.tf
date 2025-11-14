######################### NETWORKING #######################################
# RFC 1918 defines three private IP CIDR Ranges which will never
# be assigned as public IPs and cannot be routed to from the public internet#

######################### RFC 1918 Standard ################################
# Class A Block	10.0.0.0 – 10.255.255.255	10.0.0.0/8
# Class B Block	172.16.0.0 – 172.31.255.255	172.16.0.0/12
# Class C Block	192.168.0.0 – 192.168.255.255	192.168.0.0/16

######################### RESERVED IPs #####################################
# 172.31.1.1 is being used as a gateway for the public network interface of servers
# The network and broadcast IP addresses of any subnet is reserved.
# The network IP is the first IP and the broadcast IP the last IP in the CIDR range.
# For example, in 172.31.0.0/24, you cannot use 172.31.0.0 as well as 172.31.0.255
# All private traffic in subnets is routed through the subnet gateway.
# The gateway's IP address is always the first assignable IP address of the subnet's IP range:
# For example, in 172.31.0.0/24, you cannot use 172.31.0.1

######################### SUBNET SIZE #######################################
# each network gets assigned a default subnet
# when creating subnets manually, the minimum size is /30

#     __   ___        __           ___ ___       __   __
#    |  \ |__   |\/| /  \    |\ | |__   |  |  | /  \ |__) |__/
#    |__/ |___  |  | \__/    | \| |___  |  |/\| \__/ |  \ |  \
##### Network for encapsulating demo instance #####
resource "hcloud_network" "network_private_class_b_demo" {
  labels                    = local.default_labels
  name                      = "fiscalismia-private-demo-network"
  ip_range                  = var.network_private_class_b_demo
  expose_routes_to_vswitch  = false
}
resource "hcloud_network_subnet" "subnet_private_class_b_demo_isolated" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_demo.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_demo_isolated
}
resource "hcloud_network_subnet" "subnet_private_class_b_demo_exposed" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_demo.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_demo_exposed
}
#     __   __   __   __        __  ___    __                ___ ___       __   __
#    |__) |__) /  \ |  \ |  | /  `  |  | /  \ |\ |    |\ | |__   |  |  | /  \ |__) |__/
#    |    |  \ \__/ |__/ \__/ \__,  |  | \__/ | \|    | \| |___  |  |/\| \__/ |  \ |  \
##### Network for Minitoring Backend Frontend #####
resource "hcloud_network" "network_private_class_b_production" {
  labels                    = local.default_labels
  name                      = "fiscalismia-private-production-network"
  ip_range                  = var.network_private_class_b_production
  expose_routes_to_vswitch  = false
}
resource "hcloud_network_subnet" "subnet_private_class_b_production_isolated" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_production.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_production_isolated
}
resource "hcloud_network_subnet" "subnet_private_class_b_production_exposed" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_production.id
  network_zone = var.default_region
  ip_range     = var.subnet_private_class_b_production_exposed
}

#              ___     __       ___  ___                   __   __       ___  ___  __
#    |\ |  /\   |     / _`  /\   |  |__  |  |  /\  \ /    |__) /  \ |  |  |  |__  /__`
#    | \| /~~\  |     \__> /~~\  |  |___ |/\| /~~\  |     |  \ \__/ \__/  |  |___ .__/
resource "hcloud_network_route" "demo_network_internet_access_via_nat_gateway" {
  network_id  = hcloud_network.network_private_class_b_demo.id
  destination = "0.0.0.0/0"
  gateway     = var.fiscalismia_nat_gateway_private_ipv4_demo_net
}
resource "hcloud_network_route" "production_network_internet_access_via_nat_gateway" {
  network_id  = hcloud_network.network_private_class_b_production.id
  destination = "0.0.0.0/0"
  gateway     = var.fiscalismia_nat_gateway_private_ipv4_production_net
}