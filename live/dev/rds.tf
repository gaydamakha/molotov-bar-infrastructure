resource "random_password" "master" {
  length  = 16
  special = false
}

module "db_default" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.0.0"

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts
  engine               = "postgres"
  engine_version       = "14.7"
  family               = "postgres14" # DB parameter group
  major_engine_version = "14"         # DB option group

  multi_az = false

  identifier = "${local.name}-db"

  create_db_option_group    = false
  create_db_parameter_group = false

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name                     = lower("${local.name}${local.env}")
  username                    = local.db_username
  manage_master_user_password = false
  password                    = random_password.master.result
  port                        = 5432

  instance_class    = "db.t3.micro"
  storage_type      = "gp2"
  storage_encrypted = false
  allocated_storage = 20

  create_db_subnet_group = true
  subnet_ids             = module.vpc.public_subnets
  #   db_subnet_group_name   = module.vpc.database_subnet_group
  publicly_accessible    = true
  vpc_security_group_ids = [aws_security_group.rds.id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 7

  tags = {
    Terraform   = "true"
    Environment = local.env
  }
}

resource "aws_security_group" "rds" {
  name        = "rds-${local.name}-${local.env}-sg"
  description = "RDS Security Group for ${local.name} on ${local.env}"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
    cidr_blocks = [module.vpc.vpc_cidr_block]
  }

  #   ingress {
  #     from_port       = 5432
  #     to_port         = 5432
  #     protocol        = "tcp"
  #     security_groups = [var.ecs_private_task_sg_id]
  #     description     = "Allow from ECS Task in private subnet"
  #   }

  ingress {
    description = "Whitelisting of some IPs (admin/ dev)"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.db_ip_whitelist
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Terraform   = "true"
    Environment = local.env
    Name        = "RDS Security Group by TF"
  }
}
