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

resource "hcloud_firewall" "egress_public_https_icmp_only" {
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
        description     = "Allow all outbound ICMP"
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
    }
}


resource "hcloud_firewall" "egress_all_public" {
    labels = local.default_labels
    name   = "egress-all-public"

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
