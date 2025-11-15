module "bastion_host_static_ip" {
  source      = "./modules/primary_ip/"
  datacenter  = var.default_datacenter
  labels      = local.default_labels
}