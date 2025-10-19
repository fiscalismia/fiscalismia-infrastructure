terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54"
    }
  }
}

provider "hcloud" {
  # set HCLOUD_TOKEN environment variable instead
  # token = var.hcloud_token
}

locals {
  file_labels = yamldecode(file("${path.module}/.config/default.labels.yml"))
  default_labels = merge(
    local.file_labels,
    {
      environment = "development"
    }
  )
}