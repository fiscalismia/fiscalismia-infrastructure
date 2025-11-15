######################### NETWORKING #########################################################
# RFC 1918 defines three private IP CIDR Ranges which will never
# be assigned as public IPs and cannot be routed to from the public internet

######################### RFC 1918 Standard ##################################################
# Class A Block	10.0.0.0 – 10.255.255.255	10.0.0.0/8
# Class B Block	172.16.0.0 – 172.31.255.255	172.16.0.0/12
# Class C Block	192.168.0.0 – 192.168.255.255	192.168.0.0/16

######################### RESERVED IPs #######################################################
# 172.31.1.1 is being used as a gateway for the public network interface of servers
# The network and broadcast IP addresses of any subnet is reserved.
# The network IP is the first IP and the broadcast IP the last IP in the CIDR range.
# For example, in 172.31.0.0/24, you cannot use 172.31.0.0 as well as 172.31.0.255
# All private traffic in subnets is routed through the subnet gateway.
# The gateway's IP address is always the first assignable IP address of the subnet's IP range:
# For example, in 172.31.0.0/24, you cannot use 172.31.0.1

######################### SUBNET SIZE ########################################################
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

##################################### INFO ##############################################################################
# This is where the magic for internet access of private instances happens.
# 1)   The private instances setup a default route for non-local traffic to the virtual subnet gateway
# 1.1) The subnet gateway's IP address is always the first assignable IP address of the subnet's IP range.
# 1.2) e.g. for the 172.20.0.0/30 Demo Network Subnet CIDR you run "ip route add default via 172.20.0.1"
# 2)   The demo VM then knows to direct all non-local traffic to this subnet's virtual gateway.
# 3)   A hetzner network route defines that all non-local network traffic be directed to the private ip of the NAT Gateway
# 3.1) e.g. the network route in this case directs outgoing 0.0.0.0/0 traffic to "172.20.1.4" (NAT Gateway IPv4)
# 4)   The NAT Gateway is configured to forward any ipv4 traffic from the demo CIDR to its public network interface
# 4.1) e.g. you run "iptables -t nat -A POSTROUTING -s '172.20.0.0/30' -o eth0 -j MASQUERADE"
# 5)   The NAT gateway's public network interface sends the packets to the internet
# 6)   Return traffic is automatically de-NATed and forwarded back to the private VM.
##########################################################################################################################
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