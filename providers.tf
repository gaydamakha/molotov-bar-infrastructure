terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = local.region
  alias  = "master"

  assume_role {
    role_arn = "arn:aws:iam::${local.account.master}:role/TerraformCloudDeployRole"
  }

  default_tags {
    tags = {
      Organization = local.org
      Environment  = "master"
      ManagedBy    = "Terraform"
    }
  }
}
