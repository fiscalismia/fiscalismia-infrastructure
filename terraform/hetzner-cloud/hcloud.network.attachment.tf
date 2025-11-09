# resource "hcloud_server_network" "attachment_fiscalismia_backend" {
#   server_id  = module.fiscalismia_backend.server_id_list[0]
#   network_id = hcloud_network.fiscalismia_private_class_b.id
#   ip         = "172.16.0.1" # subnet 1

#   depends_on = [
#     hcloud_network_subnet.fiscalismia_private_class_b_1
#   ]
# }
# resource "hcloud_server_network" "attachment_fiscalismia_frontend" {
#   server_id  = module.fiscalismia_frontend.server_id_list[0]
#   network_id = hcloud_network.fiscalismia_private_class_b.id
#   ip         = "172.16.0.2" # subnet 1

#   depends_on = [
#     hcloud_network_subnet.fiscalismia_private_class_b_1
#   ]
# }
resource "hcloud_server_network" "attachment_fiscalismia_demo" {
  server_id  = module.fiscalismia_demo.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = "172.16.0.3" # subnet 1

  depends_on = [
    hcloud_network_subnet.fiscalismia_private_class_b_1
  ]
}
resource "hcloud_server_network" "attachment_fiscalismia_monitoring" {
  server_id  = module.fiscalismia_monitoring.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = "172.16.0.4" # subnet 1

  depends_on = [
    hcloud_network_subnet.fiscalismia_private_class_b_1
  ]
}

### SUBNET 2 for to give my "Public" Servers Private IPV4s
resource "hcloud_server_network" "attachment_ansible_control_node" {
  server_id  = module.ansible_control_node.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = "172.24.0.0" # subnet 2

  depends_on = [
    hcloud_network_subnet.fiscalismia_private_class_b_2
  ]
}
resource "hcloud_server_network" "attachment_fiscalismia_loadbalancer" {
  server_id  = module.fiscalismia_loadbalancer.server_id_list[0]
  network_id = hcloud_network.fiscalismia_private_class_b.id
  ip         = "172.24.0.1" # subnet 2

  depends_on = [
    hcloud_network_subnet.fiscalismia_private_class_b_2
  ]
}