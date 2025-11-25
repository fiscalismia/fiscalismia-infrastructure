terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "~> 1.54"
    }
    cloudinit = {
      source = "hashicorp/cloudinit"
      version = "~> 2.3.7"
    }
  }
  backend "s3" {
    bucket = "hangrybear-tf-backend-state-bucket"
    key = "fiscalismia-infrastructure/hcloud/state.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}

provider "cloudinit" {
  # Configuration options
}


provider "hcloud" {
  # set HCLOUD_TOKEN environment variable instead
  # token = var.hcloud_token
}

locals {
  file_labels = yamldecode(file("${path.module}/config/default.labels.yml"))
  default_labels = merge(
    local.file_labels,
    {
      environment = "prod"
    }
  )
}