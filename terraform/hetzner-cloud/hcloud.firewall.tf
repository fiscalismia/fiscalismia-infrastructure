resource "hcloud_firewall" "ssh_access" {
    labels = local.default_labels
    name   = "ssh-access"

    rule {
        destination_ips = []
        direction       = "in"
        port            = "22"
        protocol        = "tcp"
        source_ips = [
        "0.0.0.0/0",
        "::/0",
        ]
    }
}

resource "hcloud_firewall" "all_egress" {
    labels = local.default_labels
    name   = "all-egress"

    rule {
        direction       = "out"
        protocol        = "tcp"
        port            = "any"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow all outbound TCP"
    }

    rule {
        direction       = "out"
        protocol        = "udp"
        port            = "any"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow all outbound UDP"
    }

    rule {
        direction       = "out"
        protocol        = "icmp"
        destination_ips = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow all outbound ICMP"
    }
}

resource "hcloud_firewall" "http_ingress" {
    name = "http-ingress"

    rule {
        direction   = "in"
        protocol    = "tcp"
        port        = "80"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow HTTP from anywhere"
    }
}


resource "hcloud_firewall" "https_ingress" {
    name = "https-ingress"

    rule {
        direction   = "in"
        protocol    = "tcp"
        port        = "443"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow HTTPS from anywhere"
    }
}



resource "hcloud_firewall" "icmp_ping_ingress" {
    name = "icmp-ingress"

    rule {
        direction   = "in"
        protocol    = "icmp"
        source_ips  = [
        "0.0.0.0/0",
        "::/0"
        ]
        description = "Allow Ping (ICMP) from anywhere"
    }
}