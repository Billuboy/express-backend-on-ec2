# Configuration for AWS provider.
provider "aws" {
  region = "ap-south-1"

  default_tags {
    tags = {
      "provisioned_through" = "terraform"
    }
  }
}

data "aws_vpc" "default_vpc" {
  default = true
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

# resource "aws_lb_target_group" "alb_target_group" {
#   name                          = "demo-alb-tg"
#   port                          = 80
#   protocol                      = "HTTP"
#   vpc_id                        = data.aws_vpc.default_vpc.id
#   load_balancing_algorithm_type = "round_robin"

#   health_check {
#     enabled  = true
#     timeout  = 25
#     protocol = "HTTP"
#     path     = "/"
#   }
# }

# # output "target_group_arn" {
# #   description = "value"
# #   value       = aws_lb_target_group.alb_target_group.arn
# # }

# # output "subnets" {
# #   description = "subnets"
# #   value = data.aws_subnets.default_vpc_subnets.ids
# # }

# module "load_balancer" {
#   source = "terraform-aws-modules/alb/aws"

#   name                       = "demo-alb"
#   vpc_id                     = data.aws_vpc.default_vpc.id
#   enable_deletion_protection = false

#   subnets = data.aws_subnets.default_vpc_subnets.ids

#   # Security Group
#   security_group_ingress_rules = {
#     all_http = {
#       from_port   = 80
#       to_port     = 80
#       ip_protocol = "tcp"
#       description = "HTTP web traffic"
#       cidr_ipv4   = "0.0.0.0/0"
#     }
#   }
#   # security_group_egress_rules = {
#   #   all = {
#   #     ip_protocol = "-1"
#   #     cidr_ipv4   = "10.0.0.0/16"
#   #   }
#   # }

#   listeners = {
#     forward_to_tg = {
#       port     = 80
#       protocol = "HTTP"
#       weighted_forward = {
#         target_groups = [
#           {
#             arn              = aws_lb_target_group.alb_target_group.arn
#             # target_group_key = aws_lb_target_group.alb_target_group.name
#             weight           = 100
#           }
#         ]
#       }
#     }
#   }
# }

data "aws_ami" "ami" {
  most_recent      = true
  owners           = ["amazon"]

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

# output "ami" {
#   description = "ami-id"
#   value = data.aws_ami.ami.id
# }

resource "aws_security_group" "ec2_sg" {
  name        = "ec2-sg"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = data.aws_vpc.default_vpc.id
}

resource "aws_vpc_security_group_ingress_rule" "http_ingress_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  # cidr_ipv4         = data.aws_vpc.default_vpc.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80

}

resource "aws_vpc_security_group_egress_rule" "all_traffic_egress_rule" {
  security_group_id = aws_security_group.ec2_sg.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_launch_template" "launch_template" {
  name = "demo-lt"
  image_id = data.aws_ami.ami.id
  instance_type = "t2.micro"
  user_data = filebase64("${path.module}/init.sh")

  security_group_names = [aws_security_group.ec2_sg.name]

  # network_interfaces {
  #   associate_public_ip_address = true
  # }
}

# module "asg" {
#   source  = "terraform-aws-modules/autoscaling/aws"

#   # Autoscaling group
#   name = "demo-asg"

#   min_size                  = 1
#   max_size                  = 1
#   desired_capacity          = 1
#   wait_for_capacity_timeout = 0
#   health_check_type         = "EC2"
#   vpc_zone_identifier       = data.aws_subnets.default_vpc_subnets.ids

#   # initial_lifecycle_hooks = [
#   #   {
#   #     name                  = "ExampleStartupLifeCycleHook"
#   #     default_result        = "CONTINUE"
#   #     heartbeat_timeout     = 60
#   #     lifecycle_transition  = "autoscaling:EC2_INSTANCE_LAUNCHING"
#   #     notification_metadata = jsonencode({ "hello" = "world" })
#   #   },
#   #   {
#   #     name                  = "ExampleTerminationLifeCycleHook"
#   #     default_result        = "CONTINUE"
#   #     heartbeat_timeout     = 180
#   #     lifecycle_transition  = "autoscaling:EC2_INSTANCE_TERMINATING"
#   #     notification_metadata = jsonencode({ "goodbye" = "world" })
#   #   }
#   # ]

#   instance_refresh = {
#     strategy = "Rolling"
#     preferences = {
#       # checkpoint_delay       = 600
#       # checkpoint_percentages = [35, 70, 100]
#       instance_warmup        = 300
#       min_healthy_percentage = 50
#       max_healthy_percentage = 100
#     }
#     triggers = ["tag"]
#   }

#   # Launch template
#   launch_template_name        = "example-asg"
#   launch_template_description = "Launch template example"
#   update_default_version      = true

#   image_id          = "ami-ebd02392"
#   instance_type     = "t3.micro"
#   ebs_optimized     = true
#   enable_monitoring = true

#   # IAM role & instance profile
#   create_iam_instance_profile = true
#   iam_role_name               = "example-asg"
#   iam_role_path               = "/ec2/"
#   iam_role_description        = "IAM role example"
#   iam_role_tags = {
#     CustomIamRole = "Yes"
#   }
#   iam_role_policies = {
#     AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
#   }

#   block_device_mappings = [
#     {
#       # Root volume
#       device_name = "/dev/xvda"
#       no_device   = 0
#       ebs = {
#         delete_on_termination = true
#         encrypted             = true
#         volume_size           = 20
#         volume_type           = "gp2"
#       }
#     }, {
#       device_name = "/dev/sda1"
#       no_device   = 1
#       ebs = {
#         delete_on_termination = true
#         encrypted             = true
#         volume_size           = 30
#         volume_type           = "gp2"
#       }
#     }
#   ]

#   capacity_reservation_specification = {
#     capacity_reservation_preference = "open"
#   }

#   cpu_options = {
#     core_count       = 1
#     threads_per_core = 1
#   }

#   credit_specification = {
#     cpu_credits = "standard"
#   }

#   instance_market_options = {
#     market_type = "spot"
#     spot_options = {
#       block_duration_minutes = 60
#     }
#   }

#   # This will ensure imdsv2 is enabled, required, and a single hop which is aws security
#   # best practices
#   # See https://docs.aws.amazon.com/securityhub/latest/userguide/autoscaling-controls.html#autoscaling-4
#   metadata_options = {
#     http_endpoint               = "enabled"
#     http_tokens                 = "required"
#     http_put_response_hop_limit = 1
#   }

#   # network_interfaces = [
#   #   {
#   #     delete_on_termination = true
#   #     description           = "eth0"
#   #     device_index          = 0
#   #     security_groups       = ["sg-12345678"]
#   #   },
#   #   {
#   #     delete_on_termination = true
#   #     description           = "eth1"
#   #     device_index          = 1
#   #     security_groups       = ["sg-12345678"]
#   #   }
#   # ]

#   placement = {
#     availability_zone = "us-west-1b"
#   }

#   tag_specifications = [
#     {
#       resource_type = "instance"
#       tags          = { WhatAmI = "Instance" }
#     },
#     {
#       resource_type = "volume"
#       tags          = { WhatAmI = "Volume" }
#     },
#     {
#       resource_type = "spot-instances-request"
#       tags          = { WhatAmI = "SpotInstanceRequest" }
#     }
#   ]

#   tags = {
#     Environment = "dev"
#     Project     = "megasecret"
#   }
# }