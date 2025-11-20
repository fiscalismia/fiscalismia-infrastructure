output "server_ips_human_readable" {
  description = "A combined, nicely formatted list of all server IPs across all deployed modules."

  value = join("\n", concat(
    [""],
    ["############ PUBLIC INFRASTRUCTURE #########"],
    try(module.fiscalismia_bastion_host.server_ipv4_ascii_list, []),
    try(module.fiscalismia_loadbalancer.server_ipv4_ascii_list, []),
    try(module.fiscalismia_nat_gateway.server_ipv4_ascii_list, []),
    ["############ PRIVATE INFRASTRUCTURE ########"],
    format(" > %-30s %s", "Fiscalismia-Demo:", module.fiscalismia_demo.main_private_ipv4),
    format(" > %-30s %s", "Fiscalismia-Monitoring:", module.fiscalismia_monitoring.main_private_ipv4),
    format(" > %-30s %s", "Fiscalismia-Frontend:", module.fiscalismia_frontend.main_private_ipv4),
    format(" > %-30s %s", "Fiscalismia-Backend:", module.fiscalismia_backend.main_private_ipv4),
  ))
}