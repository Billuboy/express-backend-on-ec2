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

data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_subnets" "default_vpc_subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }
}

module "alb" {
  source = "./modules/alb"

  default_vpc_id = data.aws_vpc.default_vpc.id
  default_vpc_subnet_ids = data.aws_subnets.default_vpc_subnets.ids

}

module "asg" {
  source = "./modules/asg"

  alb_sg_id = module.alb.alb_sg_id
  alb_tg_arn = module.alb.alb_tg_arn
  default_vpc_id = data.aws_vpc.default_vpc.id
  default_region_azs =  data.aws_availability_zones.available.names
}