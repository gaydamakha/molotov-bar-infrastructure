locals {
  org     = "Molotov Bar"
  region  = "eu-central-1"
  env     = "dev"
  name    = "molotov-bar-api"
  enable  = true
  account = {
    master = "439575621641"
  }
  registry = {
    molotov-bar-api = "molotov-bar-api"
  }
  db_username     = "molotovbardbadmin"
  db_ip_whitelist = [
    "37.65.51.122/32"
  ]
  tags = {
    Organization = local.org
    Environment  = local.env
    ManagedBy    = "Terraform"
  }
  ec2_instance_type = "t3.micro"
  user_data         = <<EOF
#!/bin/bash
echo ECS_CLUSTER=${local.name}-cluster >> /etc/ecs/ecs.config
EOF
}
