output "alb_dns_name" {
  value       = aws_lb.ecommerce_lb.dns_name
  description = "DNS name of the application load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.ecommerce_tg.arn
  description = "ARN of the target group"
}
