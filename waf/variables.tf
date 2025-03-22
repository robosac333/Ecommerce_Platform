variable "alb_arn" {
  description = "ARN of the Application Load Balancer to associate with the WAF WebACL"
  type        = string
}

variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
}

variable "rate_limit" {
  description = "Maximum number of requests allowed in a 5-minute period from a single IP address"
  type        = number
  default     = 2000
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs in CloudWatch"
  type        = number
  default     = 30
}

variable "blocked_requests_threshold" {
  description = "Threshold for the number of blocked requests to trigger an alarm"
  type        = number
  default     = 100
}

variable "alarm_actions" {
  description = "List of ARNs to notify when the blocked requests alarm is triggered"
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {
    Project = "ecommerce-app"
  }
}
