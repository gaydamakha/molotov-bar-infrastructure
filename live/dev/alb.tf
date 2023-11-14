module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "9.2.0"

  name    = "my-alb"
  vpc_id  = module.vpc.name
  subnets = module.vpc.public_subnets

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
      #      cidr_ipv6   = "::/0"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      description = "HTTPS web traffic"
      cidr_ipv4   = "0.0.0.0/0"
      #      cidr_ipv6   = "::/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
      #      cidr_ipv6   = "::/0"
    }
  }

  access_logs = {
    bucket = "${local.name}-alb-logs"
  }

  #  listeners = {
  #    ex-http-https-redirect = {
  #      port     = 80
  #      protocol = "HTTP"
  #      redirect = {
  #        port        = "443"
  #        protocol    = "HTTPS"
  #        status_code = "HTTP_301"
  #      }
  #    }
  #    ex-https = {
  #      port            = 443
  #      protocol        = "HTTPS"
  #      certificate_arn = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #
  #      forward = {
  #        target_group_key = "ex-instance"
  #      }
  #    }
  #  }

  target_groups = {
    molotov-bar-api = {
      name_prefix          = "mba-"
      protocol             = "HTTP"
      port                 = 80
      target_type          = "instance"
      deregistration_delay = 30
      create_attachment    = false

      health_check = {
        enabled             = true
        interval            = 60
        path                = "/"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 15
        protocol            = "HTTP"
        matcher             = "200-399"
      }

    }
  }

  tags = {
    Environment = local.env
    Project     = local.name
  }
}