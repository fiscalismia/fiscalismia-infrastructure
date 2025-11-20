# see https://registry.terraform.io/providers/hashicorp/cloudinit/latest/docs/data-sources/config
# see https://cloudinit.readthedocs.io/en/latest/
data "cloudinit_config" "default" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.default.yml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/modules/hcloud_server/user_data/cloud-config.default.yml")
  }
}

data "cloudinit_config" "sandbox" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "sandbox.sh"
    content_type = "text/x-shellscript"
    content      = templatefile(
      "${path.module}/modules/hcloud_server/user_data/sandbox_standalone.sh",
      local.sandbox_env_vars
    )
  }

  part {
    filename     = "cloud-config.sandbox.yml"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/modules/hcloud_server/user_data/cloud-config.sandbox.yml",
      {
        ENV_VAR1 = "first value"
        ENV_VAR2 = "second value"
        sandbox_injected_b64 = local.sandbox_injected_b64
      }
    )
  }
}

data "cloudinit_config" "bastion_host" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.bastion-host.yml"
    content_type = "text/cloud-config"
    content      = templatefile(
      "${path.module}/modules/hcloud_server/user_data/cloud-config.bastion-host.yml",
      {
        nat_gw_egresss_setup_b64 = local.nat_gw_egresss_setup_b64
      }
      )
  }
}

data "cloudinit_config" "loadbalancer" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.loadbalancer.yml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/modules/hcloud_server/user_data/cloud-config.loadbalancer.yml")
  }
}

data "cloudinit_config" "demo_instance" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.demo-instance.yml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/modules/hcloud_server/user_data/cloud-config.demo-instance.yml")
  }
}

data "cloudinit_config" "nat_gateway" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.nat-gateway.yml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/modules/hcloud_server/user_data/cloud-config.nat-gateway.yml")
  }
}

data "cloudinit_config" "production_instances" {
  gzip          = false
  base64_encode = false

  part {
    filename     = "cloud-config.production-instances.yml"
    content_type = "text/cloud-config"
    content      = file("${path.module}/modules/hcloud_server/user_data/cloud-config.production-instances.yml")
  }
}
