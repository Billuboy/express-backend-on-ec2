# Fetching information for Amazon Linux 2023 AMI.
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
}

resource "aws_vpc_security_group_ingress_rule" "http_ingress_rule" {
  security_group_id            = aws_security_group.ec2_sg.id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"

  # Referencing alb security group in ingress-rule because the EC2 instances will receive requests from the ALB.
  referenced_security_group_id = var.alb_sg_id
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

  # You can attach a custom IAM policy (aka Instance Profile) to your EC2 instances.
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
  health_check_type         = "EC2"
  availability_zones        = var.default_region_azs
  launch_template {
    id = aws_launch_template.launch_template.id
  }
}

# Traffic source configuration for ASG to increase and decrease the instances in the Target Group. 
resource "aws_autoscaling_traffic_source_attachment" "asg_alb_traffic_config" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  traffic_source {
    identifier = var.alb_tg_arn
    type = "elbv2"
  }
}

# Creating a target-tracking-scaling policy for ASG.
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