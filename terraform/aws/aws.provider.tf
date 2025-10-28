terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.16"
    }
  }
  backend "s3" {
    bucket = "hangrybear-tf-backend-state-bucket"
    key = "fiscalismia-infrastructure/aws/state.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"

  default_tags {
    tags = {
      repository      = "fiscalismia-infrastructure"
      provisioned_by  = "terraform"
    }
  }
}