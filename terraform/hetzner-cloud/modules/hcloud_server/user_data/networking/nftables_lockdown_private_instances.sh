#!/bin/bash

################################ INFO ########################################################################################
# This file is intended for private instances without a public ip assigned, to which hcloud does not allow attaching firewalls
# We manually install and configure nftables, the best practice tools for firewall rules used as backend for other frameworks
# PARAM $1 is the loadbalancer private ipv4 for https ingress allowance
# PARAM $2 is the bastion-host private ipv4 for ssh ingress allowance
# PARAM $3 is the nat-gateway private ipv4 for https and http egress allowance
# PARAM $4 is the private ipv4 of the instance to lockdown in nftables
##############################################################################################################################

# wait for the private network interface to initialize.
sleep 60

export LOADBALANCER_PRIVATE_IP="$1"
export BASTION_HOST_PRIVATE_IP="$2"
export NAT_GATEWAY_PRIVATE_IP="$3"
export TARGET_INSTANCE_PRIVATE_IP="$4"

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
    echo "Error: Missing required parameters." > &2
    echo "Usage: $0 <LOADBALANCER_PRIVATE_IP> <BASTION_HOST_PRIVATE_IP> <NAT_GATEWAY_PRIVATE_IP> <TARGET_INSTANCE_PRIVATE_IP>" >&2
    exit 1
fi

sudo dnf install --quiet -y nftables
which nft
# enable nftables on boot and start immediately
echo "# Enabling and starting nftables..."
sudo systemctl enable nftables
sudo systemctl start nftables
# check nftables status
echo "# Checking status of nftables:" && sudo systemctl status nftables
