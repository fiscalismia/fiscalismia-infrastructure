resource "hcloud_ssh_key" "infrastructure_orchestration" {
  name       = "fiscalismia-infrastructure-master-key"
  public_key = file("~/.ssh/fiscalismia-infrastructure-master-key-hcloud.pub")
  labels     = local.default_labels
}

resource "hcloud_ssh_key" "demo_instance" {
  name       = "fiscalismia-demo-key"
  public_key = file("~/.ssh/fiscalismia-demo-key-hcloud.pub")
  labels     = local.default_labels
}

resource "hcloud_ssh_key" "production_instances" {
  name       = "fiscalismia-production-key"
  public_key = file("~/.ssh/fiscalismia-production-key-hcloud.pub")
  labels     = local.default_labels
}