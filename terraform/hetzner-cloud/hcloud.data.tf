locals {
  nat_gw_egresss_setup_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/nat_gw_egress_setup.sh")
  )
  install_podman_docker-compose_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/install-podman-docker-compose-fedora.sh")
  )
  sandbox_injected_b64 = base64encode(
    file("${path.module}/modules/hcloud_server/user_data/sandbox_injected.sh")
  )
  sandbox_env_vars = {
    ENV_VAR1 = "first value"
    ENV_VAR2 = "second value"
  }
}
