#!/usr/bin/env bash

################################ INFO ########################################################################################
# This file is intended for the loadbalancer, which does not have its private ipv4 traffic restricted in any way by hetzner
# We manually install and configure nftables, the best practice tools for firewall rules used as backend for other frameworks
# PARAM $1 is the bastion-host private ipv4 for ssh ingress allowance via production network
# PARAM $2 is the demo instance private ip in order to allow an additional port for the running backend
# PARAM $3 Parameter to allow additional port(s) as egress to the demo instance running frontend + backend + fastapi + golang
# PARAM $4 is the production backend instance private ip for targeted egress allowance
# PARAM $5 Parameter to allow additional port(s) as egress to the production backend instance running fastapi
# PARAM $6 is the production monitoring instance private ip for targeted egress allowance
# PARAM $7 Parameter to allow additional port(s) as egress to the production monitoring instance running golang
# e.g. ./scripts/nftables_lockdown_loadbalancer.sh 172.24.1.2 172.20.0.2 "8443,8444,8445" 172.24.0.4 "8444" 172.24.0.2 "8445"
##############################################################################################################################

# wait for the private network interface to initialize.
sleep 60

export BASTION_HOST_PRIVATE_IP="$1" # use production network private ip
export DEMO_INSTANCE_PRIVATE_IP="$2"
export APIS_DEMO_INGRESS_PORTS="$3"
export PROD_BACKEND_PRIVATE_IP="$4"
export APIS_PROD_BACKEND_INGRESS_PORTS="$5"
export PROD_MONITORING_PRIVATE_IP="$6"
export APIS_PROD_MONITORING_INGRESS_PORTS="$7"
export TABLE_NAME='lockdown_loadbalancer_private_net'
export CONFIG_PATH='/etc/sysconfig/nftables.conf'

if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]] || [[ -z "$4" ]] || [[ -z "$5" ]] || [[ -z "$6" ]] || [[ -z "$7" ]]; then
    echo "Error: Missing required parameters."
    echo "Usage: $0 <BASTION_HOST_PRIVATE_IP> <DEMO_INSTANCE_PRIVATE_IP> <APIS_DEMO_INGRESS_PORTS> <PROD_BACKEND_PRIVATE_IP> <APIS_PROD_BACKEND_INGRESS_PORTS> <PROD_MONITORING_PRIVATE_IP> <APIS_PROD_MONITORING_INGRESS_PORTS>"
    exit 1
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

        # Allow HTTPS Ingress from all addresses
        # TODO remove port 80 in production
        tcp dport {80,443} ct state new accept

        # Allow ICMP Ingress from all addresses
        icmp type echo-request accept
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

        # DNS runs on UDP, TCP is used only for large DNS queries exceeding the UDP limit e.g. in DNSSEC
        ip daddr {185.12.64.2, 185.12.64.1, 8.8.8.8} tcp dport 53 ct state new accept

        # Allow ICMP to internet and private networks
        icmp type echo-request accept

        # Allow HTTP, HTTPS to internet and private networks
        tcp dport {80,443} ct state new accept

        # Allow Network Time Protocol (NTP) to synchronize system clock via systemctl chronyd - check via "timedatectl"
        udp dport {123} ct state new accept

        # Allow HTTPS Egress to additional demo instance port
        ip daddr $DEMO_INSTANCE_PRIVATE_IP tcp dport {$APIS_DEMO_INGRESS_PORTS} ct state new accept

        # Allow Egress to production backend instance on fastapi webscraper port(s)
        ip daddr $PROD_BACKEND_PRIVATE_IP tcp dport {$APIS_PROD_BACKEND_INGRESS_PORTS} ct state new accept

        # Allow Egress to production monitoring instance on golang healthcheck port(s)
        ip daddr $PROD_MONITORING_PRIVATE_IP tcp dport {$APIS_PROD_MONITORING_INGRESS_PORTS} ct state new accept
    }

    # Drop all packages to be forwarded (we're not a gateway!)
    chain forward {
        type filter hook forward priority 0; policy drop;
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
# ls -l /etc/nftables/
# nft list tables
# nft list ruleset
# to check logs, run "journalctl -kf"
