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

# hetzner defined virtual network gateways, at first assigable ip address of network
variable "virtual_network_gateway_demo_net" {
  default = "172.20.0.1"
}
variable "virtual_network_gateway_production_net" {
  default = "172.24.0.1"
}
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
