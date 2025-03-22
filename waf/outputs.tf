output "web_acl_id" {
  value       = aws_wafv2_web_acl.ecommerce_waf.id
  description = "ID of the WAF WebACL"
}

output "web_acl_arn" {
  value       = aws_wafv2_web_acl.ecommerce_waf.arn
  description = "ARN of the WAF WebACL"
}

output "web_acl_name" {
  value       = aws_wafv2_web_acl.ecommerce_waf.name
  description = "Name of the WAF WebACL"
}

output "log_group_name" {
  value       = aws_cloudwatch_log_group.waf_logs.name
  description = "Name of the CloudWatch Log Group for WAF logs"
}

output "log_group_arn" {
  value       = aws_cloudwatch_log_group.waf_logs.arn
  description = "ARN of the CloudWatch Log Group for WAF logs"
}

output "blocked_requests_alarm_arn" {
  value       = aws_cloudwatch_metric_alarm.waf_blocked_requests.arn
  description = "ARN of the CloudWatch Alarm for blocked requests"
}
