#!/usr/bin/env bash

############ USAGE INSTRUCTIONS ##################
# PARAM $1 = log_name_specifier
# PARAM $2 = public ip (e.g. that of portquiz.net)
# ./portscan_public_egress.sh nat_gw 49.13.27.238
##################################################

set -eou pipefail

timeout_seconds=0.05
rate_limit_seconds=0.01
log_file=/tmp/portscan_public_egress_$1.log
target_server=$2
rm -f ${log_file} | true
touch ${log_file}

echo "Starting Portscan..." >> ${log_file}
date >> ${log_file}
echo "####################" >> ${log_file}

# scan all open outbound ports and write to log file
for destination_port in {1..65536}; do
  if echo printf "payload" | sudo timeout ${timeout_seconds} nc -v -p 443 ${target_server} ${destination_port}; then
    echo "port ${destination_port} is open" >> ${log_file}
    sleep ${rate_limit_seconds}
  else
    echo "port ${destination_port} returns exit code $?"
  fi
done

echo "Portscan Complete!" >> ${log_file}
date >> ${log_file}
echo "###################" >> ${log_file}
echo "Output can be found in $log_file"