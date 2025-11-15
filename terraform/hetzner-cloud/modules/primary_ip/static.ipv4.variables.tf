
variable "labels" {
  description    = "A map of key-value pairs for default labels to apply to all resources in this module"
  type           = map(string)
}
variable "datacenter" {
  description   = "The datacenter for our resources such as primary ips"
  type          = string
}