# see https://docs.hetzner.com/cloud/general/locations/#what-locations-are-there

#     __   ___  ___                ___  __
#    |  \ |__  |__   /\  |  | |     |  /__`
#    |__/ |___ |    /~~\ \__/ |___  |  .__/

variable "instance_count" {
  description   = "The number of instances to launch"
  type          = number
  default       = 1
}

variable "server_type" {
  description   = "The size and type of the Hetzner VPS"
  type          = string
  default       = "cx23" # 2vcpu 4 mem shared and cost_optimized
}

variable "protect_resource" {
  description   = "Whether or not to protect the server from deletion and rebuild."
  type          = bool
  default       = false
}

variable "image_architecture" {
  description   = "x86 or arm"
  type          = string
  default       = "x86"
}

variable "is_private" {
  description    = "Whether or not the server exposes a public IPV4"
  type           = bool
  default        = false
}

#     __   ___  __          __   ___  __
#    |__) |__  /  \ |  | | |__) |__  |  \
#    |  \ |___ \__X \__/ | |  \ |___ |__/

variable "server_name" {
  description   = "The server name"
  type          = string
}

variable "unix_distro" {
  description   = "The Unix Distribution Base Image Name to Fetch to latest Image ID from"
  type          = string
}

variable "labels" {
  description    = "A map of key-value pairs for default labels to apply to all resources in this module"
  type           = map(string)
}

variable "firewall_ids" {
  description    = "A map ids of firewalls (like security groups in AWS) to assign to the instance"
  type           = list(string)
}

variable "ssh_key_name" {
  description    = "the SSH Key to assign to these specific instances"
  type           = string
}
variable "location" {
  description   = "The location for our hcloud servers"
  type          = string
}

variable "network_id" {
  description   = "ID of our private network where all mutual instance communication happens"
  type          = string
}

variable "private_ipv4" {
  description   = "The manually assigned private IPV4 from the private subnet CIDR range"
  type          = string
}