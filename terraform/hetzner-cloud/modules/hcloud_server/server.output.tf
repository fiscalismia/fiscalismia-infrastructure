
output "server_ipv4_ascii_list" {
  description = "A nicely formatted list of server names and IPs."
  # Use the join function to format the output as a clean string list
  # Use the format function to align the server name and colon to a fixed width
  value = [
    for i, server in hcloud_server.unix_vps :
    format(" > %-30s %s", "${server.name}:", server.ipv4_address)
  ]
}

output "server_ipv4_list" {
  description = "List of IPV4 addresses."
  value = [
    for i, server in hcloud_server.unix_vps :
    server.ipv4_address
  ]
}

output "server_id_list" {
  description = "List of ids exported by tf"
  value = [
    for i, server in hcloud_server.unix_vps :
    server.id
  ]
}

output "main_private_ipv4" {
  value = var.networks[0].private_ip
}