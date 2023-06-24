terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.master]
    }
  }

  backend "remote" {
    organization = local.org

    workspaces {
      name = "business-infrastructure-common"
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
