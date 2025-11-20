#!/bin/bash

################################ INFO ####################################################################################
# This file is intended for public instances with a public ip assigned, but with firewall rules blocking all public egress
# This allows ephemeral public internet access via NAT Gateway and Private Interface Routing via Private Hetzner networks
# PARAM $1 is the private IPv4 address of the public instance wanting to gain ephemeral internet access
##########################################################################################################################

# wait for the private network interface to initialize.
sleep 60

### Variable definition ###
export log="/root/nat_gw_egress_setup.log"
# the private ip is hardcoded in terraform
export PRIVATE_IP="$1"
# name of the new routing table
export NAT_TABLE="nat_prod"
# sets the virtual network gateway (first assignable ip in network's CIDR)
export VIRTUAL_GATEWAY="172.24.0.1"
# gets the ipv4 private network interface name and save it to a variable
export PRIVATE_INTERFACE="$(ip --oneline -4 address | grep ${PRIVATE_IP} | awk '{print $2}')"
export PUBLIC_IP="$(hostname -I | awk '{print $1}')"

if ! [ -z "$1" ]; then echo "No Private IPv4 address passed as Param 1"; fi >> ${log}

### Log Variables to File###
vars=(PRIVATE_IP NAT_TABLE VIRTUAL_GATEWAY PRIVATE_INTERFACE PUBLIC_IP)
printf "\n# Private IP Settings:\n" >> "${log}"
for v in "${vars[@]}"; do echo "$v=${!v}"; done >> ${log}

### Apply Routing Changes ###
echo "100 ${NAT_TABLE}" >> /usr/share/iproute2/rt_tables
# add a link route so the kernel knows how to reach the gateway (should be configured by default in Hetzner)
ip route add ${VIRTUAL_GATEWAY} dev ${PRIVATE_INTERFACE} > /dev/null 2>&1
# Send all traffic in the NAT_TABLE to the Hetzner virtual network gateway
ip route add default via ${VIRTUAL_GATEWAY} dev ${PRIVATE_INTERFACE} table ${NAT_TABLE}
# THIS CAUSES SSH CONNECTION LOSS SO WE COMMENT IT OUT:
# ip route replace default via ${VIRTUAL_GATEWAY} dev ${PRIVATE_INTERFACE}
# Keep SSH alive. Any traffic *from* our public IP must use the main table.
ip rule add from ${PUBLIC_IP}/32 table main priority 100
# This is the new "default" for all other locally-generated traffic.
# It matches everything else and sends it to the nat_prod table.
ip rule add from all table ${NAT_TABLE} priority 200
# ip rule add from ${PRIVATE_IP}/32 table ${NAT_TABLE} priority 100
# ip rule add from ${PRIVATE_IP}/32 lookup ${NAT_TABLE}
ip route flush cache

printf "\n# Testing Connectivity via Private Interface:\n" >> ${log}
ping -c 1 -I ${PRIVATE_IP} 8.8.8.8 | grep -E 'statistics|packets transmitted' >> ${log} 2>&1
printf "\n# Public IP Exposed via Private Interface:\n" >> ${log}
curl -s --connect-timeout 5 --max-time 10 --interface ${PRIVATE_IP} https://ifconfig.me >> ${log} 2>&1
printf "\n# Testing Connectivity via Default Route:\n" >> ${log}
ping -c 1 8.8.8.8 | grep -E 'statistics|packets transmitted' >> ${log} 2>&1
printf "\n# Public IP Exposed via Default Route:\n" >> ${log}
curl -s --connect-timeout 5 --max-time 10 https://ifconfig.me >> ${log} 2>&1