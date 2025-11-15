variable "default_location" {
  description   = "The location for our hcloud servers"
  type          = string
  default       = "fsn1"
}
variable "default_datacenter" {
  description   = "The datacenter for our resources such as primary ips"
  type          = string
  default       = "fsn1-dc14"
}
variable "default_region" {
  description   = "The region for our private server network"
  type          = string
  default       = "eu-central"
}

variable "unix_distro" {
  description   = "The Linux image to use for all servers"
  type          = string
  default       = "fedora-42"
}

#     __   __              ___  ___          ___ ___       __   __        __
#    |__) |__) | \  /  /\   |  |__     |\ | |__   |  |  | /  \ |__) |__/ /__`
#    |    |  \ |  \/  /~~\  |  |___    | \| |___  |  |/\| \__/ |  \ |  \ .__/

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

variable "network_private_class_b_demo" {
  description   = "RFC 1918 Class B CIDR Range reserved for private networks"
  type          = string
  default       = "172.20.0.0/23"
}
variable "subnet_private_class_b_demo_isolated" {
  description   = "For all private instances not reachable from the public internet"
  type          = string
  default       = "172.20.0.0/30"
}
variable "subnet_private_class_b_demo_exposed" {
  description   = "For attaching public instances, required to connect to the private instances"
  type          = string
  default       = "172.20.1.0/29"
}

variable "network_private_class_b_production" {
  description   = "RFC 1918 Class B CIDR Range reserved for private networks"
  type          = string
  default       = "172.24.0.0/23"
}
variable "subnet_private_class_b_production_isolated" {
  description   = "For all private instances not reachable from the public internet"
  type          = string
  default       = "172.24.0.0/28"
}
variable "subnet_private_class_b_production_exposed" {
  description   = "For attaching public instances, required to connect to the private instances"
  type          = string
  default       = "172.24.1.0/29"
}

#     __   __              ___  ___       __   __
#    |__) |__) | \  /  /\   |  |__     | |__) /__`
#    |    |  \ |  \/  /~~\  |  |___    | |    .__/

# strictly private instances without native internet access
variable "fiscalismia_demo_private_ipv4" {
  default = "172.20.0.2"
}
variable "fiscalismia_monitoring_private_ipv4" {
  default = "172.24.0.2"
}
variable "fiscalismia_frontend_private_ipv4" {
  default = "172.24.0.3"
}
variable "fiscalismia_backend_private_ipv4" {
  default = "172.24.0.4"
}

# these instances also have a public ip assigned and must route to both private networks
variable "fiscalismia_bastion_host_private_ipv4_demo_net" {
  default = "172.20.1.2"
}
variable "fiscalismia_bastion_host_private_ipv4_production_net" {
  default = "172.24.1.2"
}
variable "fiscalismia_loadbalancer_private_ipv4_demo_net" {
  default = "172.20.1.3"
}
variable "fiscalismia_loadbalancer_private_ipv4_production_net" {
  default = "172.24.1.3"
}
variable "fiscalismia_nat_gateway_private_ipv4_demo_net" {
  default = "172.20.1.4"
}
variable "fiscalismia_nat_gateway_private_ipv4_production_net" {
  default = "172.24.1.4"
}
