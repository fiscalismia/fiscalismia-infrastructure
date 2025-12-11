#!/usr/bin/env bash

LOADBALANCER_PUBLIC_IP=$1
ncat_timeout=3
max_parallelism=500
max_processes=10000
sleep_timer=0.00001

if [[ -z $1 ]]; then
  echo "Error - Usage: $0 <LOADBALANCER_PUBLIC_IP>"
  exit 1
fi

spawn_network_request() {
  timeout $ncat_timeout nc -4 $LOADBALANCER_PUBLIC_IP 443 < /dev/null
}

for ((i = 0; i < $max_processes; i++)); do
  if (( $i > $max_parallelism )); then
    while (( $(jobs -r | wc -l) >= max_parallelism )); do
      sleep 0.5
    done
    spawn_network_request &
    sleep $sleep_timer
  fi
done