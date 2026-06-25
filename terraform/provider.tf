terraform {
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
