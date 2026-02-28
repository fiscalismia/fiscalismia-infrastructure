output "server_ips_human_readable" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ PUBLIC INFRASTRUCTURE ############"],
    try(module.fiscalismia_bastion_host.server_ipv4_ascii_list, []),
    try(module.fiscalismia_loadbalancer.server_ipv4_ascii_list, []),
    try(module.fiscalismia_nat_gateway.server_ipv4_ascii_list, []),
    try(module.network_sentinel.server_ipv4_ascii_list, []),
    [""],
    ["############ PRIVATE INFRASTRUCTURE ###########"],
    [format(" > %-30s %s", "Fiscalismia-Demo:", try(module.fiscalismia_demo.main_private_ipv4, "None"))],
    [format(" > %-30s %s", "Fiscalismia-Monitoring:", try(module.fiscalismia_monitoring.main_private_ipv4, "None"))],
    [format(" > %-30s %s", "Fiscalismia-Frontend:", try(module.fiscalismia_frontend.main_private_ipv4, "None"))],
    [format(" > %-30s %s", "Fiscalismia-Backend:", try(module.fiscalismia_backend.main_private_ipv4, "None"))],
    [format(" > %-30s %s", "Network-Sentinel:", try(module.network_sentinel.main_private_ipv4, "None"))],
    [""],
  ))
}

### output specifically for REMOTE STATE to read from
### Alternatively can parse directly from state backend s3 bucket with the following syntax:
### bastion_ip=$(cat state.tfstate | jq .outputs.fiscalismia_bastion_host_ipv4.value )
output "fiscalismia_bastion_host_ipv4" {
  value     = try(module.fiscalismia_bastion_host.server_ipv4_list, "")
  sensitive = true
}
output "fiscalismia_loadbalancer_ipv4" {
  value     = try(module.fiscalismia_loadbalancer.server_ipv4_list, "")
  sensitive = true
}
output "fiscalismia_nat_gateway_ipv4" {
  value     = try(module.fiscalismia_nat_gateway.server_ipv4_list, "")
  sensitive = true
}
output "fiscalismia_loadbalancer_private_ipv4" {
  value     = try(module.fiscalismia_loadbalancer.main_private_ipv4, "")
  sensitive = true
}
output "fiscalismia_nat_gateway_private_ipv4" {
  value     = try(module.fiscalismia_nat_gateway.main_private_ipv4, "")
  sensitive = true
}
output "fiscalismia_demo_private_ipv4" {
  value     = try(module.fiscalismia_demo.main_private_ipv4, "")
  sensitive = true
}
output "fiscalismia_monitoring_private_ipv4" {
  value     = try(module.fiscalismia_monitoring.main_private_ipv4, "")
  sensitive = true
}
output "fiscalismia_frontend_private_ipv4" {
  value     = try(module.fiscalismia_frontend.main_private_ipv4, "")
  sensitive = true
}
output "fiscalismia_backend_private_ipv4" {
  value     = try(module.fiscalismia_backend.main_private_ipv4, "")
  sensitive = true
}
output "network_sentinel_private_ipv4" {
  value     = try(module.network_sentinel.main_private_ipv4, "")
  sensitive = true
}