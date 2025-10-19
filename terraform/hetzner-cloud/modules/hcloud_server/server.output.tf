
output "server_ipv4_list" {
  description = "A nicely formatted list of server names and IPs."
  # Use the join function to format the output as a clean string list
  # Use the format function to align the server name and colon to a fixed width
  value = [
    for i, server in hcloud_server.unix_vps :
    format(" > %-30s %s", "${server.name}:", server.ipv4_address)
  ]
}