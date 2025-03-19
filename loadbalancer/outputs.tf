output "alb_dns_name" {
  value       = aws_lb.ecommerce_lb.dns_name
  description = "DNS name of the application load balancer"
}

output "target_group_arn" {
  value       = aws_lb_target_group.ecommerce_tg.arn
  description = "ARN of the target group"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.ecommerce_asg.name
  description = "Name of the Auto Scaling Group"
}

output "scale_out_policy_arn" {
  value       = aws_autoscaling_policy.scale_out.arn
  description = "ARN of the scale out policy"
}

output "scale_in_policy_arn" {
  value       = aws_autoscaling_policy.scale_in.arn
  description = "ARN of the scale in policy"
}

output "load_balancer_arn_suffix" {
  value       = aws_lb.ecommerce_lb.arn_suffix
  description = "ARN suffix of the load balancer"
}
