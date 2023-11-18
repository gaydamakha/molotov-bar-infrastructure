module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "5.7.2"
  create  = local.enable

  cluster_name                          = "${local.name}-cluster"
  default_capacity_provider_use_fargate = false
  create_task_exec_iam_role             = true
  create_cloudwatch_log_group           = true
  cluster_settings                      = {
    name  = "containerInsights"
    value = "disabled"
  }

  # Capacity provider
  autoscaling_capacity_providers = {
    # On-demand instances
    first = {
      auto_scaling_group_arn         = module.asg.autoscaling_group_arn
      managed_termination_protection = "DISABLED"

      managed_scaling = {
        maximum_scaling_step_size = 1
        minimum_scaling_step_size = 1
        status                    = "ENABLED"
        target_capacity           = 100
      }

      default_capacity_provider_strategy = {
        base   = 1
        weight = 100
      }
    }
  }

  services = {
    (local.name) = {
      name                     = local.name
      # Task Definition
      requires_compatibilities = ["EC2"]
      autoscaling_min_capacity = 0
      autoscaling_max_capacity = 1
      desired_count            = 0
      launch_type              = "EC2"
      network_mode             = "bridge"
      # Container definition(s)
      container_definitions    = {
        main = {
          cpu           = 256
          memory        = 512
          image         = "${module.registry.repositories[local.name]}:latest"
          essential     = true
          port_mappings = [
            {
              containerPort = 80
              protocol      = "tcp"
            }
          ]
        }
      }

      load_balancer = {
        service = {
          target_group_arn = module.alb.target_groups[local.name].arn
          container_name   = "main"
          container_port   = 80
        }
      }

      subnet_ids           = module.vpc.private_subnets
      security_group_rules = {
        alb_http_ingress = {
          type                     = "ingress"
          from_port                = 80
          to_port                  = 80
          protocol                 = "tcp"
          description              = "Service port"
          source_security_group_id = module.alb.security_group_id
        }
      }

      tags = local.tags
    }
  }

  tags = local.tags
}