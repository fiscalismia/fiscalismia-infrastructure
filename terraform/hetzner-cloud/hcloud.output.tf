output "server_ips_human_readable" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ FISCALISMIA INFRASTRUCTURE #########"],
    try(module.ansible_control_node.server_ipv4_ascii_list, []),
    try(module.fiscalismia_loadbalancer.server_ipv4_ascii_list, []),
    try(module.fiscalismia_monitoring.server_ipv4_ascii_list, []),
    # try(module.fiscalismia_backend.server_ipv4_ascii_list, []),
    # try(module.fiscalismia_frontend.server_ipv4_ascii_list, []),
    try(module.fiscalismia_demo.server_ipv4_ascii_list, []),
    ["#################################################"],
  ))
}

output "ansible_control_node_1_ipv4" {
  value = module.ansible_control_node.server_ipv4_list[0]
}
output "fiscalismia_load_balancer_server_1_ipv4" {
  value = module.fiscalismia_loadbalancer.server_ipv4_list[0]
}
output "fiscalismia_monitoring_server_1_ipv4" {
  value = module.fiscalismia_monitoring.server_ipv4_list[0]
}
# output "fiscalismia_backend_server_1_ipv4" {
#   value = module.fiscalismia_backend.server_ipv4_list[0]
# }
# output "fiscalismia_frontend_server_1_ipv4" {
#   value = module.fiscalismia_frontend.server_ipv4_list[0]
# }
output "fiscalismia_demo_server_1_ipv4" {
  value = module.fiscalismia_demo.server_ipv4_list[0]
}