######
# ELB
######
module "alb" {
  source = "../modules/alb"

  name = "test-project-alb"

  load_balancer_type = "application"

  vpc_id          = data.aws_vpc.default.id
  security_groups = [data.aws_security_group.default.id, "sg-02442ee979ea4c62d"]
  subnets         = data.aws_subnet_ids.all.ids

  http_tcp_listeners = [
    # Forward action is default, either when defined or undefined
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
      # action_type        = "forward"
    },
    {
      port               = 8080
      protocol           = "HTTP"
      target_group_index = 1
      # action_type        = "forward"
    },
  ]

  target_groups = [
    {
      name_prefix          = "test"
      backend_protocol     = "HTTP"
      backend_port         = 80
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/ping"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    },
    {
      name_prefix          = "test"
      backend_protocol     = "HTTP"
      backend_port         = 8080
      target_type          = "instance"
      deregistration_delay = 10
      health_check = {
        enabled             = true
        interval            = 30
        path                = "/ping"
        port                = "traffic-port"
        healthy_threshold   = 3
        unhealthy_threshold = 3
        timeout             = 6
        protocol            = "HTTP"
        matcher             = "200-399"
      }
    },
  ]

  tags = {
    Project = "test-project"
  }

  lb_tags = {
    MyLoadBalancer = "test-alb"
  }

  target_group_tags = {
    MyGlobalTargetGroupTag = "test-project"
  }
}

######
# Launch configuration and autoscaling group
######
module "autoscaling" {
  source = "../modules/autoscaling"

  name = "test-asg"

  lc_name = "test-lc"

  image_id           = data.aws_ami.amazon_linux.id
  instance_type      = "t3a.micro"
  key_name           = "ttrack"
  security_groups    = [data.aws_security_group.default.id, "sg-02442ee979ea4c62d"]
  target_group_arns  = module.alb.target_group_arns

  # Auto scaling group
  asg_name                  = "test-asg"
  vpc_zone_identifier       = data.aws_subnet_ids.all.ids
  health_check_type         = "EC2"
  min_size                  = 2
  max_size                  = 2
  desired_capacity          = 2
  wait_for_capacity_timeout = 0

  tags = [
    {
      key                 = "Environment"
      value               = "dev"
      propagate_at_launch = true
    },
    {
      key                 = "Project"
      value               = "test-project"
      propagate_at_launch = true
    },
  ]
}

