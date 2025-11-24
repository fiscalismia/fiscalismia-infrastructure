#!/usr/bin/env bash

################################ INFO #############################################################################################
# This file installs required tools for testing and verifying the nftables firewall configuration for locking down ingress & egress
# PARAM $1 is the bastion-host private ipv4 for ssh ingress allowance
# e.g. ./scripts/install-network-hardening-tools.sh /root/cloud-config.log
###################################################################################################################################

export LOG_FILE="$1"
export TOOL_SUITE='nmap nmap-ncat dig net-tools'

if [[ -z "$1" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <LOG_FILE_NAME>"
    exit 1
fi

# install networking tools for security evaluation of firewall rules
sudo dnf install $TOOL_SUITE -y --quiet
printf "\n# Installed [nmap] port scanner version:\n" >> $LOG_FILE
nmap --version >> $LOG_FILE 2>&1
printf "\n# Installed [nc] port scanner version:\n" >> $LOG_FILE
nc --version >> $LOG_FILE 2>&1
printf "\n# Installed [dig] dns resolver version:\n" >> $LOG_FILE
dig -v >> $LOG_FILE 2>&1
printf "\n# Installed [netstat] port analyzer version:\n" >> $LOG_FILE
netstat --version >> $LOG_FILE 2>&1