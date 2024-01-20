data "aws_availability_zones" "available" {}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "vpc-molotov-bar-${local.env}"
  cidr = "10.0.0.0/16"

  azs             = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = false
  enable_vpn_gateway = false

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

module "vpc_endpoints" {
  source = "terraform-aws-modules/vpc/aws/modules/vpc-endpoints"
  version = "5.0.0"

  vpc_id = module.vpc.vpc_id

  create_security_group      = true
  security_group_name_prefix = "${local.name}-vpc-endpoints-"
  security_group_description = "VPC endpoint security group"
  security_group_rules = {
    ingress_https = {
      description = "HTTPS from VPC"
      cidr_blocks = [module.vpc.vpc_cidr_block]
    }
  }

  endpoints = {
#    s3 = {
#      service             = "s3"
#      private_dns_enabled = true
#      dns_options = {
#        private_dns_only_for_inbound_resolver_endpoint = false
#      }
#      tags = { Name = "s3-vpc-endpoint" }
#    },
#    dynamodb = {
#      service         = "dynamodb"
#      service_type    = "Gateway"
#      route_table_ids = flatten([module.vpc.intra_route_table_ids, module.vpc.private_route_table_ids, module.vpc.public_route_table_ids])
#      policy          = data.aws_iam_policy_document.dynamodb_endpoint_policy.json
#      tags            = { Name = "dynamodb-vpc-endpoint" }
#    },
    ecs = {
      service             = "ecs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
    ecs_telemetry = {
      create              = false
      service             = "ecs-telemetry"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
    },
#    ecr_api = {
#      service             = "ecr.api"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#    },
#    ecr_dkr = {
#      service             = "ecr.dkr"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      policy              = data.aws_iam_policy_document.generic_endpoint_policy.json
#    },
#    rds = {
#      service             = "rds"
#      private_dns_enabled = true
#      subnet_ids          = module.vpc.private_subnets
#      security_group_ids  = [aws_security_group.rds.id]
#    },
  }

  tags = merge(local.tags, {
    Project  = local.name
    Endpoint = "true"
  })
}
# resource "aws_eip" "molotov_bar_eip" {
#   vpc = true
# }
