resource "hcloud_ssh_key" "infrastructure_orchestration" {
  name       = "fiscalismia-infrastructure-master-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_ssh_key" "demo_instance" {
  name       = "fiscalismia-demo-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}

resource "hcloud_ssh_key" "production_instances" {
  name       = "fiscalismia-production-key"
  public_key = file("~/.ssh/id_ed25519.pub")
}