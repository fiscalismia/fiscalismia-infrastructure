locals {

  ### NETWORKING ###
  nat_gw_ephemeral_public_egress_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nat_gw_ephemeral_public_egress.sh")
  )
  nftables_lockdown_private_instances_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nftables_lockdown_private_instances.sh")
  )
  nftables_lockdown_loadbalancer_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nftables_lockdown_loadbalancer.sh")
  )
  nftables_lockdown_bastion_host_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nftables_lockdown_bastion_host.sh")
  )
  nftables_lockdown_nat_gateway_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nftables_lockdown_nat_gateway.sh")
  )

  ### TOOLS ###
  install_podman_docker-compose_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/tools/install-podman-docker-compose-fedora.sh")
  )
  install_network_hardening_tools_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/tools/install-network-hardening-tools.sh")
  )
  fetch_and_validate_tls_certificates_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/tools/fetch-and-validate-tls-certificates.sh")
  )

  ### TESTS ###
  sandbox_injected_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/tests/sandbox_injected.sh")
  )
  sandbox_env_vars = {
    ENV_VAR1 = "first value"
    ENV_VAR2 = "second value"
  }
}

data "hcloud_image" "fedora_image" {
  name               = "fedora-42"
  with_architecture  = "x86"
  most_recent        = true
  with_status        = ["available"]
  include_deprecated = false
}