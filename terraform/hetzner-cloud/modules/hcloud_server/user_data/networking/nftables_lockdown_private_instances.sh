#!/usr/bin/env bash

################################ INFO ########################################################################################
# This file is intended for private instances without a public ip assigned, to which hcloud does not allow attaching firewalls
# We manually install and configure nftables, the best practice tools for firewall rules used as backend for other frameworks
# PARAM $1 is the loadbalancer private ipv4 for https ingress allowance
# PARAM $2 is the bastion-host private ipv4 for ssh ingress allowance
# PARAM $3 is the nat-gateway private ipv4 for https and http egress allowance
# PARAM $4 is the virtual network gateway used as the next-hop target for private egress to NAT-Gateway
# PARAM $5 Comma-separated list of podman ports for local NAT port forwarding for ingress & egress, e.g. '443,8443,3002,5432'
# PARAM $6 OPTIONAL Parameter to allow an additional port for ingress on the demo instance running frontend + backend
# When a new network is created with a podman network create command, and no subnet is given with the --subnet option, Podman starts picking a free subnet from 10.89.0.0/24 to 10.255.255.0/24
# e.g. ./scripts/nftables_lockdown_private_instances.sh 172.20.1.3 172.20.1.2 172.20.1.4 172.20.0.1 "443,8443,5432" 8443
##############################################################################################################################

### PODMAN NETWORKING INFO ###
# The default bridge network (called podman) uses 10.88.0.0/16 as a subnet
# When a new network is created with a podman network create command, and no subnet is given with the --subnet option,
# then Podman starts picking a free subnet from 10.89.0.0/24 to 10.255.255.0/24
# /22 CIDR allows these networks: 10.89.0.0/24 | 10.89.1.0/24 | 10.89.2.0/24 | 10.89.3.0/24
export PODMAN_NETWORK_CIDR="10.89.0.0/22"

# wait for the private network interface to initialize.
echo "Locking down private instance via minimal required nftables firewall in 60 seconds..."
sleep 60

export LOADBALANCER_PRIVATE_IP="$1"
export BASTION_HOST_PRIVATE_IP="$2"
export NAT_GATEWAY_PRIVATE_IP="$3"
export VIRTUAL_NETWORK_GATEWAY="$4"
export PODMAN_LISTENER_PORT_LIST_RAW="$5"
export PODMAN_LISTENER_PORT_LIST="{$PODMAN_LISTENER_PORT_LIST_RAW}"
export TABLE_NAME='lockdown_private_instances'
export CONFIG_PATH='/etc/sysconfig/nftables.conf'

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]] || [[ -z "$5" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <LOADBALANCER_PRIVATE_IP> <BASTION_HOST_PRIVATE_IP> <NAT_GATEWAY_PRIVATE_IP> <VIRTUAL_NETWORK_GATEWAY> <PODMAN_LISTENER_PORT_LIST_RAW> <OPTIONAL_BACKEND_DEMO_INGRESS_PORT>"
    exit 1
fi

if [[ "$6" ]]; then
    echo "Allowing additional port for demo instance: $6"
    # TODO remove port 80 in production
    export LB_INGRESS_PORTS="{80,443,$6}"
else
    # TODO remove port 80 in production
    export LB_INGRESS_PORTS="{80,443}"
fi

### INSTALLATION ###
sudo dnf install --quiet -y nftables
printf "\n# network filter tables installed binary path:\n"
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

        # Drop all ingress for all protocols by default unless explicitly allowed
        type filter hook input priority 0; policy drop;

        # Allow loopback to localhost for internal services
        iif lo accept

        # Allow established and related connections
        ct state established,related accept

        # Allow SSH Ingress from Bastion Host
        ip saddr $BASTION_HOST_PRIVATE_IP tcp dport 22 ct state new accept

        # Allow HTTPS Ingress from Loadbalancer
        ip saddr $LOADBALANCER_PRIVATE_IP tcp dport $LB_INGRESS_PORTS ct state new accept

        # Allow ICMP Ping Ingress from Loadbalancer
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

    # Configure podman networking allowing port forwarding without having to use the hack network_mode: host
    chain forward {
        type filter hook forward priority 0; policy drop;

        # Allow established and related connections
        ct state established,related accept

        # Allow podman interinter-container communication within the entire network subnet CIDR
        ip saddr $PODMAN_NETWORK_CIDR ip daddr $PODMAN_NETWORK_CIDR ip protocol tcp accept

        # Allow ingress from loadbalancer to podman network subnet CIDR on specified ports
        ip daddr $PODMAN_NETWORK_CIDR tcp dport $PODMAN_LISTENER_PORT_LIST ct state new accept

        # Allow container responses back out of the network
        ip saddr $PODMAN_NETWORK_CIDR tcp sport $PODMAN_LISTENER_PORT_LIST ct state new accept
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
# nft list ruleset
# nft add rule ip lockdown_private_instances input ip saddr 172.20.1.5 udp dport 500 ct state new accept
# nft add rule ip lockdown_private_instances input udp dport 501 ct state new accept

# nft add rule ip lockdown_private_instances input ip saddr 172.24.1.3 tcp dport {80,443} ct state new accept
# nft add rule ip lockdown_private_instances input ip saddr 172.24.1.3 icmp type echo-request accept
