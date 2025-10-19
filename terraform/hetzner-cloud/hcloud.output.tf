output "server_ips" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ FISCALISMIA INFRASTRUCTURE #########"],
    try(module.ansible_control_node.server_ipv4_list, []),
    # try(module.fiscalismia_backend.server_ipv4_list, []),
    # try(module.fiscalismia_frontend.server_ipv4_list, []),
    try(module.fiscalismia_demo.server_ipv4_list, []),
    ["#################################################"],
  ))
}