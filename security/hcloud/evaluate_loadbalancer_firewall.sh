#!/usr/bin/env bash

# example list extracted from terraform/hetzner-cloud/config/network.private.ips.yml with yq
# virtual_network_gateway_demo_net:172.20.0.1 virtual_network_gateway_production_net:172.24.0.1 fiscalismia_demo_private_ipv4:172.20.0.2 fiscalismia_monitoring_private_ipv4:172.24.0.2 fiscalismia_frontend_private_ipv4:172.24.0.3 fiscalismia_backend_private_ipv4:172.24.0.4 fiscalismia_bastion_host_private_ipv4_demo_net:172.20.1.2 fiscalismia_bastion_host_private_ipv4_production_net:172.24.1.2 fiscalismia_loadbalancer_private_ipv4_demo_net:172.20.1.3 fiscalismia_loadbalancer_private_ipv4_production_net:172.24.1.3 fiscalismia_nat_gateway_private_ipv4_demo_net:172.20.1.4 fiscalismia_nat_gateway_private_ipv4_production_net:172.24.1.4

if [ -z "$1" ]; then
  echo "ERROR: Instance list parameter not provided." >&2
  exit 1
fi

instance_list_string="$1"
instance_ips=($instance_list_string)
success_count=0
error_count=0

echo ""
echo "################# ICMP EVALUATION #############################"
date
for instance in "${instance_ips[@]}"; do
  ip_address="${instance#*:}"
  variable_name="${instance%:*}"
  ping -c 1 -W 0.02 "$ip_address" > /dev/null 2>&1
  if (( $? > 0 )); then
    error_count=$((++error_count))
    echo "ERROR: $variable_name ping timed out."
  else
    success_count=$((++success_count))
    echo "OK: $variable_name ping resolves"
  fi
done
echo "################# METRICS #####################################"
echo "SUCCESS Count: $success_count"
echo "ERROR Count: $error_count"