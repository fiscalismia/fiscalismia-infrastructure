resource "hcloud_firewall" "default" {
labels = var.labels
name   = "firewall"

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

resource "hcloud_firewall" "default-egress" {
labels = var.labels
name   = "default-egress"

rule {
    direction       = "out"
    port            = "53"
    protocol        = "tcp"
    destination_ips = [
    "0.0.0.0/0",
    "::/0",
    ]
}

rule {
    direction       = "out"
    port            = "53"
    protocol        = "udp"
    destination_ips = [
    "0.0.0.0/0",
    "::/0",
    ]
}
}