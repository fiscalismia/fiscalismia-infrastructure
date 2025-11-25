output "server_ips_human_readable" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ PUBLIC INFRASTRUCTURE ############"],
    try(module.fiscalismia_bastion_host.server_ipv4_ascii_list, []),
    try(module.fiscalismia_loadbalancer.server_ipv4_ascii_list, []),
    try(module.fiscalismia_nat_gateway.server_ipv4_ascii_list, []),
    [""],
    ["############ PRIVATE INFRASTRUCTURE ###########"],
    [format(" > %-30s %s", "Fiscalismia-Demo:", module.fiscalismia_demo.main_private_ipv4)],
    [format(" > %-30s %s", "Fiscalismia-Monitoring:", module.fiscalismia_monitoring.main_private_ipv4)],
    [format(" > %-30s %s", "Fiscalismia-Frontend:", module.fiscalismia_frontend.main_private_ipv4)],
    [format(" > %-30s %s", "Fiscalismia-Backend:", module.fiscalismia_backend.main_private_ipv4)],
    [""],
  ))
}

### output specifically for AWS REMOTE STATE to read from
### marking as sensitive to hide from cli output since these are redundant
output "fiscalismia_bastion_host_ipv4" {
  value     = try(module.fiscalismia_bastion_host.server_ipv4_list[0], null)
  sensitive = true
}
output "fiscalismia_loadbalancer_ipv4" {
  value     = try(module.fiscalismia_loadbalancer.server_ipv4_list[0], null)
  sensitive = true
}
output "fiscalismia_nat_gateway_ipv4" {
  value     = try(module.fiscalismia_nat_gateway.server_ipv4_list[0], null)
  sensitive = true
}
output "fiscalismia_loadbalancer_private_ipv4" {
  value     = try(module.fiscalismia_loadbalancer.main_private_ipv4, null)
  sensitive = true
}
output "fiscalismia_nat_gateway_private_ipv4" {
  value     = try(module.fiscalismia_nat_gateway.main_private_ipv4, null)
  sensitive = true
}
output "fiscalismia_demo_private_ipv4" {
  value     = try(module.fiscalismia_demo.main_private_ipv4, null)
  sensitive = true
}
output "fiscalismia_monitoring_private_ipv4" {
  value     = try(module.fiscalismia_monitoring.main_private_ipv4, null)
  sensitive = true
}
output "fiscalismia_frontend_private_ipv4" {
  value     = try(module.fiscalismia_frontend.main_private_ipv4, null)
  sensitive = true
}
output "fiscalismia_backend_private_ipv4" {
  value     = try(module.fiscalismia_backend.main_private_ipv4, null)
  sensitive = true
}