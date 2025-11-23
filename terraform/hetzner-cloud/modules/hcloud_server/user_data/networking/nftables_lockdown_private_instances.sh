#!/usr/bin/env bash

################################ INFO ########################################################################################
# This file is intended for private instances without a public ip assigned, to which hcloud does not allow attaching firewalls
# We manually install and configure nftables, the best practice tools for firewall rules used as backend for other frameworks
# PARAM $1 is the loadbalancer private ipv4 for https ingress allowance
# PARAM $2 is the bastion-host private ipv4 for ssh ingress allowance
# PARAM $3 is the nat-gateway private ipv4 for https and http egress allowance
# PARAM $4 is the virtual network gateway used as the next-hop target for private egress to NAT-Gateway
# e.g. ./scripts/nftables_lockdown_private_instances.sh 172.20.1.3 172.20.1.2 172.20.1.4 172.20.0.1
##############################################################################################################################

# wait for the private network interface to initialize.
sleep 60

export LOADBALANCER_PRIVATE_IP="$1"
export BASTION_HOST_PRIVATE_IP="$2"
export NAT_GATEWAY_PRIVATE_IP="$3"
export VIRTUAL_NETWORK_GATEWAY="$4"
export TABLE_NAME='lockdown_private_instances'
export CONFIG_PATH='/etc/sysconfig/nftables.conf'

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <LOADBALANCER_PRIVATE_IP> <BASTION_HOST_PRIVATE_IP> <NAT_GATEWAY_PRIVATE_IP> <VIRTUAL_NETWORK_GATEWAY>"
    exit 1
fi

### INSTALLATION ###
sudo dnf install --quiet -y nftables
which nft

### CONFIGURATION ###

cat << EOF > $CONFIG_PATH
#!/usr/sbin/nft -f

# Delete previous table
table ip $TABLE_NAME
delete table ip $TABLE_NAME

# Create new IPv4 table
table ip $TABLE_NAME {

    # Filter ingress traffic
    chain input {

        # Drop all ingress by default unless explicitly allowed
        type filter hook input priority 0; policy drop;

        # Allow loopback to localhost for internal services
        iif lo accept

        # Allow established and related connections
        ct state established,related accept

        # Allow SSH Ingress from Bastion Host
        ip saddr $BASTION_HOST_PRIVATE_IP tcp dport 22 ct state new accept

        # Allow HTTPS & ICMP Ingress from Loadbalancer
        # TODO remove port 80 in production
        ip saddr $LOADBALANCER_PRIVATE_IP tcp dport {80,443} ct state new accept
        ip saddr $LOADBALANCER_PRIVATE_IP icmp type echo-request accept
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

        # Allow ICMP to internet
        icmp type echo-request accept

        # Allow HTTP, HTTPS to internet
        tcp dport {80,443} ct state new accept
    }

    # Drop all packages to be forwarded (we're not a gateway!)
    chain forward {
        type filter hook forward priority 0; policy drop;
    }
}
EOF

# Allow Layer 2 Address Resolution only for the Virtual Network Gateway MAC Address
# table arp demo_arp {
#     chain input {
#         type filter hook input priority 0; policy drop;

#         # Allow ARP reply from the virtual network gateway
#         arp saddr $VIRTUAL_NETWORK_GATEWAY accept
#     }

#     chain output {
#         type filter hook output priority 0; policy drop;

#         # Allow ARP request targeted at the virtual network gateway
#         arp daddr $VIRTUAL_NETWORK_GATEWAY accept

#     }
# }

### START SERVICE ###
echo "# Enabling and starting nftables with $CONFIG_PATH..."
sudo chmod a+x $CONFIG_PATH
sudo $CONFIG_PATH
sudo nft list tables
sudo nft list ruleset
sudo systemctl enable nftables
sudo systemctl start nftables
echo "# Checking status of nftables:"
sudo systemctl status nftables

### DEBUG ###
# ls -l /etc/nftables/ # example nft configs not activated
