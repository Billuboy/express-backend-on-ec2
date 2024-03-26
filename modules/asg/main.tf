data "aws_ami" "ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }

  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = var.default_vpc_id
  # vpc_id      = data.aws_vpc.default_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "http_ingress_rule" {
  security_group_id            = aws_security_group.ec2_sg.id
  from_port                    = 80
  ip_protocol                  = "tcp"
  to_port                      = 80
  referenced_security_group_id = var.alb_sg_id
  # referenced_security_group_id = module.load_balancer.security_group_id
}

resource "aws_vpc_security_group_egress_rule" "all_traffic_egress_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "launch_template" {
  name                   = "demo-lt"
  image_id               = data.aws_ami.ami.id
  instance_type          = "t3.micro"
  user_data              = filebase64("./init.sh")
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  # iam_instance_profile {
  #   arn = 
  # }
}

resource "aws_autoscaling_group" "asg" {
  name                      = "demo-asg"
  max_size                  = 1
  desired_capacity          = 1
  min_size                  = 0
  health_check_grace_period = 300
  health_check_type         = "ELB"
  availability_zones        = var.default_region_azs
  # availability_zones        = data.aws_availability_zones.available.names
  launch_template {
    id = aws_launch_template.launch_template.id
  }
}

resource "aws_autoscaling_traffic_source_attachment" "asg_alb_traffic_config" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  traffic_source {
    identifier = var.alb_tg_arn
    # identifier = aws_lb_target_group.alb_target_group.arn
    type       = "elbv2"
  }
}

resource "aws_autoscaling_policy" "auto_scaling_policy" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  name                   = "avg-cpu-less-than-60-policy"
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    target_value = 60
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
  }
}