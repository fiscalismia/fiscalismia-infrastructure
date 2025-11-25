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