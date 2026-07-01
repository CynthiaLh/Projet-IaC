terraform {
  backend "s3" {
    bucket = "ynov-iac-2026-tfstate-cynthia"
    key    = "state/terraform.tfstate"
    region = "eu-west-1"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1" # Can be overriden
  default_tags {
    tags = {
      Project = "ynov-iac-2026"
    }
  }
}
