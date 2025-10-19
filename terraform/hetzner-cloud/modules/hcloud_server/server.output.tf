
output "server_ipv4_list" {
  description = "A nicely formatted list of server names and IPs."
  # Use the join function to format the output as a clean string list
  value = join("\n", [
    for i, server in hcloud_server.unix_vps :
    "${server.name}: ${server.ipv4_address}"
  ])
}