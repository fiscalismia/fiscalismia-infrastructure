### SUBNET 1 for all private instances not reachable from the public internet
# resource "hcloud_server_network" "attachment_fiscalismia_backend" {
#   server_id  = module.fiscalismia_backend.server_id_list[0]
#   network_id = hcloud_network.fiscalismia_private_class_b.id
#   ip         = var.fiscalismia_backend_private_ipv4

#   depends_on = [
#     hcloud_network_subnet.fiscalismia_private_class_b_1
#   ]
# }
# resource "hcloud_server_network" "attachment_fiscalismia_frontend" {
#   server_id  = module.fiscalismia_frontend.server_id_list[0]
#   network_id = hcloud_network.fiscalismia_private_class_b.id
#   ip         = var.fiscalismia_frontend_private_ipv4

#   depends_on = [
#     hcloud_network_subnet.fiscalismia_private_class_b_1
#   ]
# }
resource "hcloud_server_network" "attachment_fiscalismia_demo" {
  server_id  = module.fiscalismia_demo.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = var.fiscalismia_demo_private_ipv4

  depends_on = [
    module.fiscalismia_demo,
    hcloud_network_subnet.fiscalismia_private_class_b_1
  ]
}
resource "hcloud_server_network" "attachment_fiscalismia_monitoring" {
  server_id  = module.fiscalismia_monitoring.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = var.fiscalismia_monitoring_private_ipv4

  depends_on = [
    module.fiscalismia_monitoring,
    hcloud_network_subnet.fiscalismia_private_class_b_1
  ]
}

### SUBNET 2 for to give my "Public" Servers Private IPV4s in Class B Range
resource "hcloud_server_network" "attachment_ansible_control_node" {
  server_id  = module.ansible_control_node.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = var.ansible_control_node_private_ipv4

  depends_on = [
    module.ansible_control_node,
    hcloud_network_subnet.fiscalismia_private_class_b_2
  ]
}
resource "hcloud_server_network" "attachment_fiscalismia_loadbalancer" {
  server_id  = module.fiscalismia_loadbalancer.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = var.fiscalismia_loadbalancer_private_ipv4

  depends_on = [
    module.fiscalismia_loadbalancer,
    hcloud_network_subnet.fiscalismia_private_class_b_2
  ]
}