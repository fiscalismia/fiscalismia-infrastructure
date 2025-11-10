output "server_ips_human_readable" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ FISCALISMIA INFRASTRUCTURE #########"],
    try(module.fiscalismia_bastion_host.server_ipv4_ascii_list, []),
    try(module.fiscalismia_loadbalancer.server_ipv4_ascii_list, []),
    try(module.fiscalismia_monitoring.server_ipv4_ascii_list, []),
    # try(module.fiscalismia_backend.server_ipv4_ascii_list, []),
    # try(module.fiscalismia_frontend.server_ipv4_ascii_list, []),
    try(module.fiscalismia_demo.server_ipv4_ascii_list, []),
    ["#################################################"],
  ))
}

output "fiscalismia_bastion_host_server_1_ipv4" {
  value = module.fiscalismia_bastion_host.server_ipv4_list[0]
}
output "fiscalismia_load_balancer_server_1_ipv4" {
  value = module.fiscalismia_loadbalancer.server_ipv4_list[0]
}
### PRIVATE INSTANCES WITHOUT PUBLIC IP
output "fiscalismia_monitoring_server_1_ipv4" {
  value = var.fiscalismia_monitoring_private_ipv4
}
output "fiscalismia_backend_server_1_ipv4" {
  value = var.fiscalismia_backend_private_ipv4
}
output "fiscalismia_frontend_server_1_ipv4" {
  value = var.fiscalismia_frontend_private_ipv4
}
output "fiscalismia_demo_server_1_ipv4" {
  value = var.fiscalismia_demo_private_ipv4
}