terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "hangrybear-tf-backend-state-bucket"
    key = "fiscalismia-infrastructure/state.tfstate"
    region = "eu-central-1"
    encrypt = true
  }
}

provider "aws" {
  region = "eu-central-1"
}