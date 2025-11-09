# set HCLOUD_TOKEN environment variable instead
# variable "hcloud_token" {
#   sensitive       = true
#   type            = string
#   description     = "API Access Token for Hetzner Cloud"
# }

variable "default_location" {
  description   = "The location for our hcloud servers"
  type          = string
  default       = "fsn1"
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

variable "subnet_private_class_b_1_cidr" {
  description   = "Subnet 1 for strictly private instances not reachable from the public internet"
  type          = string
  default       = "172.16.0.0/16"
}
variable "subnet_private_class_b_2_cidr" {
  description   = "Subnet 2 to assign my instances reachable from the public internet their private IPV4s"
  type          = string
  default       = "172.24.0.0/16"
}

#     __   __              ___  ___       __   __
#    |__) |__) | \  /  /\   |  |__     | |__) /__`
#    |    |  \ |  \/  /~~\  |  |___    | |    .__/
variable "fiscalismia_backend_private_ipv4" {
  default = "172.16.0.1" # subnet 1
}
variable "fiscalismia_frontend_private_ipv4" {
  default = "172.16.0.2" # subnet 1
}
variable "fiscalismia_demo_private_ipv4" {
  default = "172.16.0.3" # subnet 1
}
variable "fiscalismia_monitoring_private_ipv4" {
  default = "172.16.0.4" # subnet 1
}
variable "ansible_control_node_private_ipv4" {
  default = "172.24.0.1" # subnet 2
}
variable "fiscalismia_loadbalancer_private_ipv4" {
  default = "172.24.0.2" # subnet 2
}