resource "aws_lb_target_group" "alb_target_group" {
  name                          = "demo-alb-tg"
  port                          = 80
  protocol                      = "HTTP"
  vpc_id                        = var.default_vpc_id
  # vpc_id                        = data.aws_vpc.default_vpc.id
  load_balancing_algorithm_type = "round_robin"
  health_check {
    enabled  = true
    timeout  = 25
    protocol = "HTTP"
    path     = "/"
  }
}

module "load_balancer" {
  source                     = "terraform-aws-modules/alb/aws"
  name                       = "demo-alb"
  vpc_id                     = var.default_vpc_id
  # vpc_id                     = data.aws_vpc.default_vpc.id
  enable_deletion_protection = false
  subnets                    = var.default_vpc_subnet_ids
  # subnets                    = data.aws_subnets.default_vpc_subnets.ids
  security_group_name        = "alb-sg"
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }
  listeners = {
    forward_to_tg = {
      port     = 80
      protocol = "HTTP"
      weighted_forward = {
        target_groups = [
          {
            arn    = aws_lb_target_group.alb_target_group.arn
            weight = 100
          }
        ]
      }
    }
  }
}
