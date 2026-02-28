module "bastion_host_static_ip" {
  source          = "./modules/primary_ip/"
  primary_ip_name = "bastion-host-static-ipv4"
  location        = var.default_location
  labels          = local.default_labels
}
module "loadbalancer_static_ip" {
  source          = "./modules/primary_ip/"
  primary_ip_name = "loadbalancer-static-ipv4"
  location        = var.default_location
  labels          = local.default_labels
}