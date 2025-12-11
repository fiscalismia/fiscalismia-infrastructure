#!/usr/bin/env bash

# example list extracted from terraform/hetzner-cloud/config/network.private.ips.yml with yq
if [[ -z "$1" ]]; then
  echo "ERROR: Instance list parameter not provided." >&2
  exit 1
fi

instance_list_string="$1"
instance_ips=($instance_list_string)
ncat_timeout=0.5
sleep_timer=0.005
ping_timeout=0.25
success_count=0
error_count=0

echo ""
echo "Evaluating Loadbalancer Connectivity to Private Network Targets"
date
echo "################# ICMP EVALUATION #############################"
for instance in "${instance_ips[@]}"; do
  ip_address="${instance#*:}"
  variable_name="${instance%:*}"
  ping -c 1 -W $ping_timeout "$ip_address" > /dev/null 2>&1
  exit_code=$?
  if (( exit_code == 0 )); then
    success_count=$((++success_count))
    echo "OK: $variable_name ping resolves"
  elif (( exit_code > 0 )); then
    error_count=$((++error_count))
    echo "ERROR: $variable_name ping timed out."
  fi
  sleep $sleep_timer
done
echo "===> RESULTS | SUCCESS Count: $success_count | ERROR Count: $error_count <==="

echo ""
echo "################# TCP EVALUATION #############################"
for instance in "${instance_ips[@]}"; do
  success_count=0
  error_count=0
  ip_address="${instance#*:}"
  variable_name="${instance%:*}"
  if [[ "$variable_name" == *"demo_private_ip"* ]] || \
    [[ "$variable_name" == *"monitoring_private_ip"* ]] || \
    [[ "$variable_name" == *"frontend_private_ip"* ]] || \
    [[ "$variable_name" == *"backend_private_ip"* ]];then
    printf "\n##### Testing TCP ports for $variable_name at address $ip_address...\n"
    for port in {80,443}; do
      # EXECUTE NETCAT PORTSCAN COMMAND
      timeout $ncat_timeout nc -vz4 $ip_address $port > /dev/null 2>&1
      exit_code=$?
      if (( exit_code == 0 )); then
        success_count=$((++success_count))
        echo "OK: $variable_name port $port is reachable [has listener]"
      elif (( exit_code == 1 )); then
        success_count=$((++success_count))
        echo "OK: $variable_name port $port is reachable [but refuses connection]"
      elif (( exit_code > 1 )); then
        error_count=$((++error_count))
        echo "ERROR: $variable_name port $port timeout [blocked by firewall]"
      fi
      sleep $sleep_timer
    done
    echo "===> RESULTS | SUCCESS Count: $success_count | ERROR Count: $error_count <==="
  fi
done
echo "###############################################################"