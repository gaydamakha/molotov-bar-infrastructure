terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.7.0"
    }
  }

  backend "remote" {
    organization = "molotov-bar"

    workspaces {
      name = "molotov-bar-infrastructure-dev"
    }
  }
}

provider "aws" {
  region = local.region

  assume_role {
    role_arn = "arn:aws:iam::${local.account.master}:role/TerraformCloudDeployRole"
  }

  default_tags {
    tags = {
      Organization = local.org
      Environment  = local.env
      ManagedBy    = "Terraform"
    }
  }
}
