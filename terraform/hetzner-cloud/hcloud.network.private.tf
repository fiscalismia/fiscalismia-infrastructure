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
# For example, in 172.20.0.0/23, you cannot use 172.20.0.0 as well as 172.20.0.255
# All private traffic in subnets is routed through the singular virtual network gateway.
# The gateway's IP address is always the first assignable IP address of the networks IP range:
# For example, in 172.20.0.0/23, you cannot use 172.20.0.1

######################### SUBNET SIZE ########################################################
# each network gets assigned a default subnet
# when creating subnets manually, the minimum size is /30


locals {
  network_config = yamldecode(file("${path.module}/config/network.private.ips.yml"))

  # Demo Instance Network
  network_private_class_b_demo                = local.network_config.networks.demo.cidr
  subnet_private_class_b_demo_isolated        = local.network_config.networks.demo.subnets.isolated
  subnet_private_class_b_demo_exposed         = local.network_config.networks.demo.subnets.exposed

  # Production Instances Network
  network_private_class_b_production         = local.network_config.networks.production.cidr
  subnet_private_class_b_production_isolated = local.network_config.networks.production.subnets.isolated
  subnet_private_class_b_production_exposed  = local.network_config.networks.production.subnets.exposed

  # Hetzner assigned Virtual Network Gateways
  virtual_network_gateway_demo_net           = local.network_config.ips.gateways.demo
  virtual_network_gateway_production_net     = local.network_config.ips.gateways.production

  # strictly private instances
  fiscalismia_demo_private_ipv4                             = local.network_config.ips.private_instances.demo
  fiscalismia_monitoring_private_ipv4                       = local.network_config.ips.private_instances.monitoring
  fiscalismia_frontend_private_ipv4                         = local.network_config.ips.private_instances.frontend
  fiscalismia_backend_private_ipv4                          = local.network_config.ips.private_instances.backend

  # Private IPs of publicly exposed instances
  fiscalismia_bastion_host_private_ipv4_demo_net            = local.network_config.ips.exposed_instances.bastion_host.demo
  fiscalismia_bastion_host_private_ipv4_production_net      = local.network_config.ips.exposed_instances.bastion_host.production
  fiscalismia_loadbalancer_private_ipv4_demo_net            = local.network_config.ips.exposed_instances.loadbalancer.demo
  fiscalismia_loadbalancer_private_ipv4_production_net      = local.network_config.ips.exposed_instances.loadbalancer.production
  fiscalismia_nat_gateway_private_ipv4_demo_net             = local.network_config.ips.exposed_instances.nat_gateway.demo
  fiscalismia_nat_gateway_private_ipv4_production_net       = local.network_config.ips.exposed_instances.nat_gateway.production
  fiscalismia_network_sentinel_private_ipv4_demo_net        = local.network_config.ips.exposed_instances.network_sentinel.demo
  fiscalismia_network_sentinel_private_ipv4_production_net  = local.network_config.ips.exposed_instances.network_sentinel.production
}

#     __   ___        __           ___ ___       __   __
#    |  \ |__   |\/| /  \    |\ | |__   |  |  | /  \ |__) |__/
#    |__/ |___  |  | \__/    | \| |___  |  |/\| \__/ |  \ |  \
##### Network for encapsulating demo instance #####
resource "hcloud_network" "network_private_class_b_demo" {
  labels                    = local.default_labels
  name                      = "fiscalismia-private-demo-network"
  ip_range                  = local.network_private_class_b_demo
  expose_routes_to_vswitch  = false
}
resource "hcloud_network_subnet" "subnet_private_class_b_demo_isolated" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_demo.id
  network_zone = var.default_region
  ip_range     = local.subnet_private_class_b_demo_isolated
}
resource "hcloud_network_subnet" "subnet_private_class_b_demo_exposed" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_demo.id
  network_zone = var.default_region
  ip_range     = local.subnet_private_class_b_demo_exposed
}
#     __   __   __   __        __  ___    __                ___ ___       __   __
#    |__) |__) /  \ |  \ |  | /  `  |  | /  \ |\ |    |\ | |__   |  |  | /  \ |__) |__/
#    |    |  \ \__/ |__/ \__/ \__,  |  | \__/ | \|    | \| |___  |  |/\| \__/ |  \ |  \
##### Network for Minitoring Backend Frontend #####
resource "hcloud_network" "network_private_class_b_production" {
  labels                    = local.default_labels
  name                      = "fiscalismia-private-production-network"
  ip_range                  = local.network_private_class_b_production
  expose_routes_to_vswitch  = false
}
resource "hcloud_network_subnet" "subnet_private_class_b_production_isolated" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_production.id
  network_zone = var.default_region
  ip_range     = local.subnet_private_class_b_production_isolated
}
resource "hcloud_network_subnet" "subnet_private_class_b_production_exposed" {
  type         = "cloud"
  network_id   = hcloud_network.network_private_class_b_production.id
  network_zone = var.default_region
  ip_range     = local.subnet_private_class_b_production_exposed
}

#              ___     __       ___  ___                   __   __       ___  ___  __
#    |\ |  /\   |     / _`  /\   |  |__  |  |  /\  \ /    |__) /  \ |  |  |  |__  /__`
#    | \| /~~\  |     \__> /~~\  |  |___ |/\| /~~\  |     |  \ \__/ \__/  |  |___ .__/

##################################### INFO ##############################################################################
# This is where the magic for internet access of private instances happens.
# 1)   The private instances setup a default route for non-local traffic to the network's singular virtual gateway
# 1.1) The network gateway's IP address is always the first assignable IP address of the network CIDR range.
# 1.2) e.g. for the Demo Network 172.20.0.0/23 you run "ip route add default via 172.20.0.1"
# 2)   The demo VM then knows to direct all non-local traffic to this virtual gateway.
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
  gateway     = local.fiscalismia_nat_gateway_private_ipv4_demo_net
}
resource "hcloud_network_route" "production_network_internet_access_via_nat_gateway" {
  network_id  = hcloud_network.network_private_class_b_production.id
  destination = "0.0.0.0/0"
  gateway     = local.fiscalismia_nat_gateway_private_ipv4_production_net
}
