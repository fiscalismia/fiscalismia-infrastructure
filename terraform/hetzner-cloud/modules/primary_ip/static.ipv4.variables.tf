
variable "labels" {
  description    = "A map of key-value pairs for default labels to apply to all resources in this module"
  type           = map(string)
}
variable "location" {
  description   = "The location for our resources such as primary ips"
  type          = string
}
variable "primary_ip_name" {
  description   = "Name of the resource"
  type          = string
}