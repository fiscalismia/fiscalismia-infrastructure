#!/usr/bin/env bash

################################ INFO ########################################################################################
# This file is intended for the NAT-Gateway, which does not have its private ipv4 traffic restricted in any way by hetzner
# We manually install and configure nftables, the best practice tools for firewall rules used as backend for other frameworks
# PARAM $1 is the CIDR Range of the Demo subnet for private instances
# PARAM $2 is the CIDR Range of the Demo subnet to give public instances their private IP
# PARAM $3 is the CIDR Range of the Production subnet for private instances
# PARAM $4 is the CIDR Range of the Production subnet to give public instances their private IP
# PARAM $5 is the bastion-host private ipv4 for ssh ingress allowance via production network
# e.g. ./scripts/nftables_lockdown_nat_gateway.sh 172.20.0.0/30 172.20.1.0/29 172.24.0.0/28 172.24.1.0/29 172.24.1.2
##############################################################################################################################

# wait for the private network interface to initialize.
sleep 60

export DEMO_SUBNET_ISOLATED_CIDR="$1"
export DEMO_SUBNET_EXPOSED_CIDR="$2"
export PRODUCTION_SUBNET_ISOLATED_CIDR="$3"
export PRODUCTION_SUBNET_EXPOSED_CIDR="$4"
export BASTION_HOST_PRIVATE_IP="$5" # use production network private ip
export TABLE_NAME='lockdown_nat_gateway_private_net'
export CONFIG_PATH='/etc/sysconfig/nftables.conf'

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]] || [[ -z "$5" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <DEMO_SUBNET_ISOLATED_CIDR> <DEMO_SUBNET_EXPOSED_CIDR> <PRODUCTION_SUBNET_ISOLATED_CIDR> <PRODUCTION_SUBNET_EXPOSED_CIDR> <BASTION_HOST_PRIVATE_IP>"
    exit 1
fi

nft_location=$(which nft)
if ! [[ -z "$nft_location" ]]; then
    echo "nft install path: $nft_location" && echo "$(nft --version)"
else
    echo "Error: nftables not found." && exit 1
fi

### CONFIGURATION ###

cat << EOF > $CONFIG_PATH
#!/usr/sbin/nft -f

# Delete previous table
table ip $TABLE_NAME
delete table ip $TABLE_NAME

# Create new IPv4 table
table ip $TABLE_NAME {

    define PRIVATE_SUBNETS = {
        $DEMO_SUBNET_ISOLATED_CIDR, $DEMO_SUBNET_EXPOSED_CIDR, $PRODUCTION_SUBNET_ISOLATED_CIDR, $PRODUCTION_SUBNET_EXPOSED_CIDR
    }

    # Filter ingress traffic
    chain input {

        # Drop all ingress for all protocols by default unless explicitly allowed
        type filter hook input priority 0; policy drop;

        # Allow loopback to localhost for internal services
        iif lo accept

        # Allow established and related connections
        ct state established,related accept

        # Allow SSH Ingress from Bastion Host
        ip saddr $BASTION_HOST_PRIVATE_IP tcp dport 22 ct state new accept

        # Allow HTTP & HTTPS Ingress from private networks
        ip saddr \$PRIVATE_SUBNETS tcp dport {80,443} ct state new accept

        # Allow ICMP Ingress from private networks
        ip saddr \$PRIVATE_SUBNETS icmp type echo-request accept

        # Allow DNS Ingress from private networks
        # LIKELY REDUNDANT since DNS target address is in public internet
        # ip saddr \$PRIVATE_SUBNETS udp dport 53 ct state new accept
    }

    # Allow outbound http, https, dns, icmp
    chain output {
        # Drop all egress by default unless explicitly allowed
        type filter hook output priority 0; policy drop;

        # Allow Loopback
        oif lo accept

        # Allow established and related connections
        ct state established,related accept

        # Allow DNS queries to Hetzner DNS Servers and the Fallback DNS Server
        ip daddr {185.12.64.2, 185.12.64.1, 8.8.8.8} udp dport 53 ct state new accept

        # Allow ICMP to internet and private networks
        icmp type echo-request accept

        # Allow HTTP, HTTPS to internet and private networks
        tcp dport {80,443} ct state new accept
    }
}

# perform Network Address Translation for public internet access via private inbound routes
table ip nat {
    chain POSTROUTING {

        # Add default source NAT policy
        type nat hook postrouting priority srcnat; policy accept;

		ip saddr 172.20.0.0/30 ct state new counter packets 0 bytes 0 log prefix "NAT-GW-NEW DEMO_ISOLATED: "
		ip saddr 172.20.0.0/30 counter packets 0 bytes 0 log prefix "NAT-GW DEMO_ISOLATED: "

		ip saddr 172.24.0.0/28 ct state new counter packets 0 bytes 0 log prefix "NAT-GW-NEW PROD_ISOLATED: "
		ip saddr 172.24.0.0/28 counter packets 0 bytes 0 log prefix "NAT-GW PROD_ISOLATED: "

		ip saddr 172.24.1.0/29 ct state new counter packets 0 bytes 0 log prefix "NAT-GW-NEW PROD_EXPOSED : "
		ip saddr 172.24.1.0/29 counter packets 0 bytes 0 log prefix "NAT-GW PROD_EXPOSED : "

        # subnet_private_class_b_demo_isolated
		oifname "eth0" ip saddr 172.20.0.0/30 counter packets 0 bytes 0 masquerade

        # subnet-translate_private_class_b_production_isolated
		oifname "eth0" ip saddr 172.24.0.0/28 counter packets 0 bytes 0 masquerade

        # subnet-translate_private_class_b_production_exposed
		oifname "eth0" ip saddr 172.24.1.0/29 counter packets 0 bytes 0 masquerade
    }
}
EOF

### START SERVICE ###
echo "# Enabling and starting nftables with $CONFIG_PATH..."
sudo chmod a+x $CONFIG_PATH
sudo $CONFIG_PATH
printf "\n# Listing network filter tables:\n"
sudo nft list tables
printf "\n# Listing network filter rulesets:\n"
sudo nft list ruleset
printf "\n# Enabling and starting nftables systemd service...\n"
sudo systemctl enable nftables
sudo systemctl start nftables
printf "\n# Checking status of nftables:\n"
sudo systemctl status nftables

### DEBUG ###
# ls -l /etc/nftables/ # example nft configs not activated
# nft list tables
# to check logs, run "journalctl -kf"
