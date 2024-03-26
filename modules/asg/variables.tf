variable "default_vpc_id" {
  type = string
}

variable "alb_sg_id" {
  type = string
}

variable "alb_tg_arn" {
  type = string
}

variable "default_region_azs" {
  type = list(string)
}