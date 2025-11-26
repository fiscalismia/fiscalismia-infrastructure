#!/usr/bin/env bash

# example list extracted from terraform/hetzner-cloud/config/network.private.ips.yml with yq
# virtual_network_gateway_demo_net:172.20.0.1 virtual_network_gateway_production_net:172.24.0.1 fiscalismia_demo_private_ipv4:172.20.0.2 fiscalismia_monitoring_private_ipv4:172.24.0.2 fiscalismia_frontend_private_ipv4:172.24.0.3 fiscalismia_backend_private_ipv4:172.24.0.4 fiscalismia_bastion_host_private_ipv4_demo_net:172.20.1.2 fiscalismia_bastion_host_private_ipv4_production_net:172.24.1.2 fiscalismia_loadbalancer_private_ipv4_demo_net:172.20.1.3 fiscalismia_loadbalancer_private_ipv4_production_net:172.24.1.3 fiscalismia_nat_gateway_private_ipv4_demo_net:172.20.1.4 fiscalismia_nat_gateway_private_ipv4_production_net:172.24.1.4

if [ -z "$1" ]; then
  echo "ERROR: Instance list parameter not provided." >&2
  exit 1
fi

instance_list_string="$1"
instance_ips=($instance_list_string)
open_count=0
closed_count=0
ping_timeout=0.1
# modify these for portscan stability
max_parallelism=250
ncat_timeout=0.25
sleep_timer=0.0005
nth_port=100
min_port=1
max_port=65536

printf "\n"
echo "Evaluating Network-Sentinel Connectivity to Private Network Targets"
date

#     __          __        __         __
#    |__) | |\ | / _`    | /  `  |\/| |__)
#    |    | | \| \__>    | \__,  |  | |
printf "\n"
echo "################# ICMP EVALUATION #######################################"
for instance in "${instance_ips[@]}"; do
  ip_address="${instance#*:}"
  variable_name="${instance%:*}"
  ping -c 1 -W $ping_timeout "$ip_address" > /dev/null 2>&1
  exit_code=$?
  if (( exit_code == 0 )); then
    open_count=$((++open_count))
    echo "OK: $variable_name ping resolves"
  elif (( exit_code > 0 )); then
    closed_count=$((++closed_count))
    echo "ERROR: $variable_name ping timed out."
  fi
done
echo "===> RESULTS | OPEN Count: $open_count | CLOSED Count: $closed_count <==="

#     __   __   __  ___  __   __               ___  __   __
#    |__) /  \ |__)  |  /__` /  `  /\  |\ |     |  /  ` |__)
#    |    \__/ |  \  |  .__/ \__, /~~\ | \|     |  \__, |
# Function for scanning one target port and iterating global port status
scan_ncat_port() {
  local conn_log=$1
  local port_log=$2
  local var_name=$3
  local ip=$4
  local port=$5
  NCAT_OUTPUT=$(timeout $ncat_timeout nc -vz4 $ip $port 2>&1)
  exit_code=$?
  if (( exit_code == 0 )); then
    echo "OPEN" >> $conn_log
    printf "$port " >> $port_log
    echo "OK: $var_name port $port is reachable [has listener]"
  elif (( exit_code == 1 )); then
    if [[ "$NCAT_OUTPUT" == *"No route to host"* ]];then
      echo "CLOSED" >> $conn_log
    elif [[ "$NCAT_OUTPUT" == *"Connection refused"* ]]; then
      echo "OPEN" >> $conn_log
      printf "$port " >> $port_log
      # echo "OK: $var_name port $port is reachable [but refuses connection]"
    else
      echo "CLOSED" >> $conn_log
    fi
  elif (( exit_code > 1 )); then
      echo "CLOSED" >> $conn_log
    # echo "ERROR: $var_name port $port timeout [blocked by firewall]"
  fi
}

printf "\n"
echo "################# TCP EVALUATION #######################################"
for instance in "${instance_ips[@]}"; do
  open_count=0
  closed_count=0
  connection_log=$(mktemp)
  open_port_log=$(mktemp)
  ip_address="${instance#*:}"
  variable_name="${instance%:*}"
  # Scan all Private IPs in network, except the network_sentinel itself
  if [[ "$variable_name" == *"private_ip"* ]] \
    && ! [[ "$variable_name" == *"network_sentinel"* ]];then
    printf "\n##### Testing TCP ports for $variable_name at address $ip_address...\n"
    for ((port=$min_port; port <= $max_port; port++)); do
      # while the number of lines returned by listing parallel jobs is below max_parallelism
      # but only check once every nth_port
      if (( (port % $nth_port) == 0 ));then
        while (( $(jobs -r | wc -l) >= max_parallelism)); do
          sleep 0.5
        done
      fi
      scan_ncat_port $connection_log $open_port_log $variable_name $ip_address $port &
      sleep $sleep_timer
    done

    # wait for parallel executions to finish so counts update with final value
    wait

    # subprocesses in bash cannot update global variables, so we use a temporary disk solution
    open_count=$(grep -c "OPEN" $connection_log)
    closed_count=$(grep -c "CLOSED" $connection_log)

    echo "====> RESULTS <===="
    echo "OPEN   Ports: $open_count"
    if (( $open_count == 0 )); then
      echo "PORT    List: NONE"
    elif (( $open_count > 10 )); then
      echo "PORT    List: too large to display"
    else
      echo "PORT    List: $(cat $open_port_log)"
    fi
    echo "CLOSED Ports: $closed_count"

    rm -f $connection_log 2>&1
    rm -f $open_port_log 2>&1
  fi
done
printf "\n"
date
echo "#########################################################################"