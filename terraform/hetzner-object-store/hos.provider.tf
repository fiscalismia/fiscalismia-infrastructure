terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_region_validation      = true
  endpoints {
    s3 = "https://fsn1.your-objectstorage.com"
  }
  region = "fsn1"
  # Please checks the docs on how to store those credentials safely.
  access_key = ""
  secret_key = ""
}