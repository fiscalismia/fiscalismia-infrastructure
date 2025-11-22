locals {

  ### NETWORKING ###
  nat_gw_ephemeral_public_egress_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nat_gw_ephemeral_public_egress.sh")
  )
  nftables_lockdown_private_instances_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/networking/nftables_lockdown_private_instances.sh")
  )

  ### TOOLS ###
  install_podman_docker-compose_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/tools/install-podman-docker-compose-fedora.sh")
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
