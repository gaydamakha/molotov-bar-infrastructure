data "aws_ssm_parameter" "ecs_optimized_ami_image_id" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "7.2.0"
  create  = local.enable

  # Autoscaling group
  name = "${local.name}-asg"

  min_size                  = 0
  max_size                  = 1
  desired_capacity          = 1
  wait_for_capacity_timeout = 0
  health_check_type         = "EC2"
  health_check_grace_period = 60
  vpc_zone_identifier       = module.vpc.private_subnets

  # Launch template
  launch_template_name        = "${local.name}-asg"
  launch_template_description = "Launch template for ${local.name}"
  launch_template_version     = "$Latest"
  user_data                   = base64encode(local.user_data)
  update_default_version      = true

  image_id          = data.aws_ssm_parameter.ecs_optimized_ami_image_id.value
  instance_type     = local.ec2_instance_type
  enable_monitoring = true

  # IAM role & instance profile
  create_iam_instance_profile = local.enable
  iam_role_name               = "${local.name}-asg-role"
  iam_role_path               = "/ec2/"
  iam_role_description        = "IAM role for ${local.name}"
  iam_role_tags               = {
    CustomIamRole = "Yes"
  }
  iam_role_policies = {
    AmazonEC2ContainerServiceforEC2Role = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
    AmazonSSMManagedInstanceCore        = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  }

  # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
  # best practices
  # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
  metadata_options = {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  network_interfaces = [
    {
      delete_on_termination = true
      description           = "eth0"
      device_index          = 0
      security_groups       = [module.asg_sg.security_group_id]
    },
    {
      delete_on_termination = true
      description           = "eth1"
      device_index          = 1
      security_groups       = [module.asg_sg.security_group_id]
    }
  ]

  placement = {
    availability_zone = local.region
  }

  tag_specifications = [
    {
      resource_type = "instance"
      tags          = { WhatAmI = "Instance" }
    }
  ]

  tags = {
    Environment = local.env
    Project     = local.name
  }
  autoscaling_group_tags = {
    ReservedTargetInstance = "ECS-Instance${local.name}-cluster"
    AmazonECSManaged       = true
  }
}

module "asg_sg" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = local.name
  description = "A security group"
  vpc_id      = module.vpc.vpc_id

  computed_ingress_with_source_security_group_id = [
    {
      rule                     = "http-80-tcp"
      source_security_group_id = module.alb.security_group_id
    }
  ]
  number_of_computed_ingress_with_source_security_group_id = 1

  egress_rules = ["all-all"]

  tags = local.tags
}