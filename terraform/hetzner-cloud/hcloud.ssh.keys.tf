resource "hcloud_ssh_key" "infrastructure_orchestration" {
  name       = "fiscalismia-infrastructure-master-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-infrastructure-master-key-hcloud.pub")
  labels     = local.default_labels
}
resource "hcloud_ssh_key" "load_balancer_instance" {
  name       = "fiscalismia-loadbalancer-instance-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-loadbalancer-instance-key-hcloud.pub")
  labels     = local.default_labels
}
resource "hcloud_ssh_key" "nat_gateway_instance" {
  name       = "fiscalismia-nat-gateway-instance-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-nat-gateway-instance-key-hcloud.pub")
  labels     = local.default_labels
}
resource "hcloud_ssh_key" "demo_instance" {
  name       = "fiscalismia-demo-instance-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-demo-instance-key-hcloud.pub")
  labels     = local.default_labels
}
resource "hcloud_ssh_key" "monitoring_instance" {
  name       = "fiscalismia-monitoring-instance-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-monitoring-instance-key-hcloud.pub")
  labels     = local.default_labels
}
resource "hcloud_ssh_key" "production_instances" {
  name       = "fiscalismia-production-instances-key-hcloud"
  public_key = file("~/.ssh/fiscalismia-production-instances-key-hcloud.pub")
  labels     = local.default_labels
}

