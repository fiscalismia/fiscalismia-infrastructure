########################### INFO #########################################################################
# WARNING: Hetzner allows all outbound traffic by default if no explicit outbound firewall rule is applied
# INFO:    All ingress is blocked by default and only explicit allow rules are applied
##########################################################################################################
#            __   __   ___  __   __
#    | |\ | / _` |__) |__  /__` /__`
#    | | \| \__> |  \ |___ .__/ .__/


resource "hcloud_firewall" "public_ssh_ingress" {
    labels = local.default_labels
    name   = "public-ssh-ingress"

    rule {
        description     = "Allow SSH port 22 Access from everywhere"
        direction       = "in"
        port            = "22"
        protocol        = "tcp"
        source_ips = [
        "0.0.0.0/0",
        "::/0",
        ]
    }
}

resource "hcloud_firewall" "public_haproxy_stats_ingress" {
    labels = local.default_labels
    name   = "public-haproxy-stats-ingress"

    rule {
        description     = "Allow port 8404 Access from everywhere"
        direction       = "in"
        port            = "8404"
        protocol        = "tcp"
        source_ips = [
        "0.0.0.0/0",
        "::/0",
        ]
    }
}

resource "hcloud_firewall" "public_icmp_ping_ingress" {
    name = "public-icmp-ping-ingress"

    rule {
        description = "Allow Ping (ICMP) in from anywhere"
        direction   = "in"
        protocol    = "icmp"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
    }
}

resource "hcloud_firewall" "public_https_ingress" {
    name = "public-https-ingress"

    rule {
        description = "Allow HTTPS in from anywhere"
        direction   = "in"
        protocol    = "tcp"
        port        = "443"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    # TODO: only use for testing - in production we want mTLS
    rule {
        description = "Allow HTTP in from anywhere"
        direction   = "in"
        protocol    = "tcp"
        port        = "80"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
    }
}

#     ___  __   __   ___  __   __
#    |__  / _` |__) |__  /__` /__`
#    |___ \__> |  \ |___ .__/ .__/

# INFO: if any outbound rule is defined, the default for all other outbound traffic switches to DENY
# so we simply allow outbound tcp to the server's own loopback address to block all egrress
resource "hcloud_firewall" "egress_DENY_ALL_public" {
    labels = local.default_labels
    name   = "egress-DENY-ALL-public"

    rule {
        description     = "Allow all outbound TCP"
        direction       = "out"
        protocol        = "tcp"
        port            = "any"
        destination_ips = [
        "127.0.0.1/32",
        ]
    }
}

resource "hcloud_firewall" "egress_ALLOW_ALL_public" {
    labels = local.default_labels
    name   = "egress-ALLOW-ALL-public"

    rule {
        description     = "Allow all outbound TCP"
        direction       = "out"
        protocol        = "tcp"
        port            = "any"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    rule {
        description     = "Allow all outbound UDP"
        direction       = "out"
        protocol        = "udp"
        port            = "any"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    rule {
        description     = "Allow all outbound ICMP"
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }
}

# Rule specifically for the NAT-Gateway to provide outbound internet access to private instances
resource "hcloud_firewall" "egress_public_http_https_dns_icmp" {
    labels = local.default_labels
    name   = "egress-public-https-icmp-only"

    rule {
        description     = "Allow all outbound HTTPS"
        direction       = "out"
        protocol        = "tcp"
        port            = "443"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    rule {
        description     = "Allow all outbound HTTP"
        direction       = "out"
        protocol        = "tcp"
        port            = "80"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    rule {
        description     = "Allow all outbound DNS"
        direction       = "out"
        protocol        = "udp"
        port            = "53"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }

    rule {
        description     = "Allow all outbound ICMP"
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }
}