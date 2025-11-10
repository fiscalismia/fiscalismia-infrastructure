#            __   __   ___  __   __
#    | |\ | / _` |__) |__  /__` /__`
#    | | \| \__> |  \ |___ .__/ .__/

resource "hcloud_firewall" "private_ssh_ingress_from_bastion_host" {
    labels = local.default_labels
    name   = "private-ssh-ingress-from-bastion"

    rule {
        description     = "Allow SSH port 22 Access from Bastion Host only"
        direction       = "in"
        port            = "22"
        protocol        = "tcp"
        source_ips  = [
            var.fiscalismia_loadbalancer_private_ipv4
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
            var.fiscalismia_loadbalancer_private_ipv4
        ]
    }
}

resource "hcloud_firewall" "private_https_ingress_from_loadbalancer" {
    name = "private-https-ingress-lb"

    rule {
        description = "Allow HTTPS from the Load Balancer only"
        direction   = "in"
        protocol    = "tcp"
        port        = "443"
        source_ips  = [
            var.fiscalismia_loadbalancer_private_ipv4
        ]
    }
    # TODO: only use for testing - in production we want mTLS
    rule {
        description = "Allow HTTP from the Load Balancer only"
        direction   = "in"
        protocol    = "tcp"
        port        = "80"
        source_ips  = [
            var.fiscalismia_loadbalancer_private_ipv4
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
            var.subnet_private_class_b_1_cidr,
            var.subnet_private_class_b_2_cidr
        ]
    }

    # TODO: only use for testing - in production we want mTLS
    rule {
        description     = "Allow HTTP Port 80 to instances in private class B subnet address range"
        direction       = "out"
        protocol        = "tcp"
        port            = "80"
        destination_ips = [
            var.subnet_private_class_b_1_cidr,
            var.subnet_private_class_b_2_cidr
        ]
    }
}

resource "hcloud_firewall" "egress_ssh_to_private_subnet_cidr_ranges" {
    labels = local.default_labels
    name   = "egress-ssh-to-private-instances-only"

    rule {
        description     = "Allow SSH Port 22 to instances in private class B subnet address range"
        direction       = "out"
        protocol        = "tcp"
        port            = "22"
        destination_ips = [
            var.subnet_private_class_b_1_cidr,
            var.subnet_private_class_b_2_cidr
        ]
    }
}
resource "hcloud_firewall" "egress_icmp_to_private_subnet_cidr_ranges" {
    labels = local.default_labels
    name   = "egress-icmp-to-private-instances-only"

    rule {
        description     = "Allow ICMP pings to instances in private class B subnet address range"
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
            var.subnet_private_class_b_1_cidr,
            var.subnet_private_class_b_2_cidr
        ]
    }
}