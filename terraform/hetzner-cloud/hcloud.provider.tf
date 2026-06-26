terraform {
  required_providers {
    hcloud = {
      # See https://registry.terraform.io/providers/hetznercloud/hcloud/latest/docs
      source  = "hetznercloud/hcloud"
      version = "~> 1.66.0"
    }
    cloudinit = {
      # See https://registry.terraform.io/providers/hashicorp/cloudinit/latest
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

# cloudinit offers an automated way to configure and provision fresh linux machine images
provider "cloudinit" {
}

provider "hcloud" {
  # set HCLOUD_TOKEN environment variable instead of hardcoding any secrets here
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