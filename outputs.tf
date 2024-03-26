output "alb_dns" {
  description = "Please check your ALB here"
  value       = "http://${module.alb.alb_dns}"
}