output "alb_tg_arn" {
  value = aws_lb_target_group.alb_target_group.arn
}

output "alb_sg_id" {
  value = module.load_balancer.security_group_id
}

output "alb_dns"{
  value = module.load_balancer.dns_name
}