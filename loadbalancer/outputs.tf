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

output "alb_arn" {
  value       = aws_lb.ecommerce_lb.arn
  description = "ARN of the application load balancer"
}

output "https_listener_arn" {
  value       = aws_lb_listener.https.arn
  description = "ARN of the HTTPS listener"
}

output "acm_certificate_arn" {
  value       = aws_acm_certificate.domain_cert.arn
  description = "ARN of the ACM certificate used for HTTPS"
}

output "domain_name" {
  value       = var.domain_name
  description = "Domain name used for the website"
}

output "www_domain_name" {
  value       = "www.${var.domain_name}"
  description = "WWW subdomain used for the website"
}

output "route53_zone_id" {
  value       = data.aws_route53_zone.domain_zone.zone_id
  description = "Route 53 hosted zone ID for the domain"
}
