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