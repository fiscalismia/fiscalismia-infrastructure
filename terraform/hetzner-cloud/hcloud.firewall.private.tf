########################### INFO ####################################################################
# WARNING: This file is purely cosmetic. Hetzner allows all private network communication by default
# so explicitly allowing it via these firewall rules attached to public instances is redundant
# Private Instances without assigned public ip cannot have firewalls attached.
# So we do not define their rules here, but rather on the instances themselves via "nftables"
#####################################################################################################
#            __   __   ___  __   __
#    | |\ | / _` |__) |__  /__` /__`
#    | | \| \__> |  \ |___ .__/ .__/


resource "hcloud_firewall" "private_ssh_ingress_from_bastion_host" {
    labels = local.default_labels
    name   = "private-ssh-ingress-bastion"

    rule {
        description     = "Allow SSH port 22 Access from Bastion Host only"
        direction       = "in"
        port            = "22"
        protocol        = "tcp"
        source_ips  = [
            local.fiscalismia_bastion_host_private_ipv4_demo_net,
            local.fiscalismia_bastion_host_private_ipv4_production_net,
        ]
    }
}
resource "hcloud_firewall" "private_icmp_ping_ingress_from_loadbalancer" {
    name = "private-icmp-ingress-lb"

    rule {
        description = "Allow Ping (ICMP) from the Load Balancer only"
        direction   = "in"
        protocol    = "icmp"
        source_ips  = [
            local.fiscalismia_loadbalancer_private_ipv4_demo_net,
            local.fiscalismia_loadbalancer_private_ipv4_production_net,
        ]
    }
}

#     ___  __   __   ___  __   __
#    |__  / _` |__) |__  /__` /__`
#    |___ \__> |  \ |___ .__/ .__/

resource "hcloud_firewall" "egress_https_to_private_subnet_cidr_ranges" {
    labels = local.default_labels
    name   = "egress-https-to-private-instances-only"

    rule {
        description     = "Allow HTTPS Port 443 to instances in private class B subnet address range"
        direction       = "out"
        protocol        = "tcp"
        port            = "443"
        destination_ips = [
            local.subnet_private_class_b_demo_isolated,
            local.subnet_private_class_b_production_isolated,
            local.subnet_private_class_b_production_exposed, # ipv4 of public instances in production net
        ]
    }

    # TODO: only use for testing - in production we want mTLS
    rule {
        description     = "Allow HTTP Port 80 to instances in private class B subnet address range"
        direction       = "out"
        protocol        = "tcp"
        port            = "80"
        destination_ips = [
            local.subnet_private_class_b_demo_isolated,
            local.subnet_private_class_b_production_isolated,
            local.subnet_private_class_b_production_exposed, # ipv4 of public instances in production net
        ]
    }
}

resource "hcloud_firewall" "egress_ssh_to_fiscalismia_instances" {
    labels = local.default_labels
    name   = "egress-ssh-to-private-instances-only"

    rule {
        description     = "Allow SSH Port 22 egress to all fiscalismia instances in the infrastructure"
        direction       = "out"
        protocol        = "tcp"
        port            = "22"
        destination_ips = [
            local.subnet_private_class_b_demo_isolated,
            local.subnet_private_class_b_production_isolated,
            local.subnet_private_class_b_demo_exposed,       # ipv4 of public instances in demo net
            local.subnet_private_class_b_production_exposed, # ipv4 of public instances in production net
        ]
    }
}
resource "hcloud_firewall" "egress_icmp_to_private_subnet_cidr_ranges" {
    labels = local.default_labels
    name   = "egress-icmp-to-private-instances-only"

    rule {
        description     = "Allow ICMP pings to all fiscalismia instances in the infrastructure"
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
            local.subnet_private_class_b_demo_isolated,
            local.subnet_private_class_b_production_isolated,
            local.subnet_private_class_b_demo_exposed,       # ipv4 of public instances in demo net
            local.subnet_private_class_b_production_exposed, # ipv4 of public instances in production net
        ]
    }
}