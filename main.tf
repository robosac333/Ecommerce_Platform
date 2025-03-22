terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.24"
    }
  }

  cloud {
    organization = "shantanu-gonade-org"
    workspaces {
      name = "ecommerce-workspace"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  eu_availability_zone = var.eu_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
}

module "ec2" {
  source    = "./ec2"
  subnet_id = module.networking.public_subnet_id
  vpc_id    = module.networking.ecommerce_vpc_id
  vpc_name  = var.vpc_name
}

# Call the RDS module
module "rds" {
  source = "./rds" 

  vpc_id    = module.networking.ecommerce_vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id

  # Database configuration
  # NOTE: In a production environment, these credentials should be stored in AWS Secrets Manager
  # or AWS Parameter Store and retrieved at runtime, not in terraform.tfvars
  db_username = var.db_username
  db_password = var.db_password
  db_name     = var.db_name

  # Encryption configuration
  storage_encrypted = true
  kms_key_id        = var.kms_key_id
}

# This module sets up an Application Load Balancer (ALB) for distributing traffic
module "loadbalancer" {
  source                    = "./loadbalancer"
  vpc_id                    = module.networking.ecommerce_vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  instance_security_group_id = module.ec2.security_group_id
  instance_id               = module.ec2.instance_id
}

# This module configures monitoring and auto-scaling alarms for the application
module "cloudwatch" {
  source                  = "./cloudwatch"
  prefix                  = "ecommerce"
  aws_region              = "us-east-1"
  autoscaling_group_name  = module.loadbalancer.autoscaling_group_name
  scale_out_policy_arn    = module.loadbalancer.scale_out_policy_arn
  scale_in_policy_arn     = module.loadbalancer.scale_in_policy_arn
  load_balancer_arn_suffix = module.loadbalancer.load_balancer_arn_suffix

  # Alarm thresholds
  high_cpu_threshold      = 70
  low_cpu_threshold       = 30
  high_network_threshold  = 5000000
  high_request_count_threshold = 1000
  high_response_time_threshold = 1

  # Evaluation settings
  evaluation_periods      = 2
  period                  = 300

  # Enable/disable specific alarms
  enable_network_alarms   = true
  enable_request_count_alarm = true
  enable_response_time_alarm = true

  # Create a dashboard
  create_dashboard        = true
  
  # WAF dashboard settings
  waf_enabled             = true
  waf_web_acl_name        = "ecommerce-waf-acl"

  tags = {
    Project = "ecommerce-app"
  }
}

# This module sets up Web Application Firewall rules and protection
module "waf" {
  source      = "./waf"
  alb_arn     = module.loadbalancer.alb_arn
  aws_region  = "us-east-1"
  
  # Rate limiting settings
  rate_limit  = 2000
  
  # Logging settings
  log_retention_days = 30
  
  # Alarm settings
  blocked_requests_threshold = 100
  
  # Optional: Add SNS topic ARNs for alarm notifications
  # alarm_actions = ["arn:aws:sns:us-east-1:123456789012:waf-alerts"]
  
  tags = {
    Project = "ecommerce-app"
  }
}

# Create the security group rules AFTER both modules are created
resource "aws_security_group_rule" "ec2_to_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.rds.rds_security_group_id
  security_group_id        = module.ec2.security_group_id
  description              = "Allow MySQL connections to RDS"
}

resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.ec2.security_group_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow MySQL connections from EC2 instances"
}

# ================================================================

# Output values from the module
output "instance_public_ip" {
  value = module.ec2.instance_public_ip
}

output "website_url" {
  value = module.ec2.website_url
}

# Add loadbalancer outputs
output "alb_dns_name" {
  value = module.loadbalancer.alb_dns_name
}

# Add CloudWatch outputs
output "high_cpu_alarm_arn" {
  value       = module.cloudwatch.high_cpu_alarm_arn
  description = "ARN of the high CPU utilization alarm"
}

output "low_cpu_alarm_arn" {
  value       = module.cloudwatch.low_cpu_alarm_arn
  description = "ARN of the low CPU utilization alarm"
}

output "autoscaling_group_name" {
  value       = module.loadbalancer.autoscaling_group_name
  description = "Name of the Auto Scaling Group"
}

output "cloudwatch_dashboard_arn" {
  value       = module.cloudwatch.dashboard_arn
  description = "ARN of the CloudWatch dashboard"
}

# Add WAF outputs
output "waf_web_acl_id" {
  value       = module.waf.web_acl_id
  description = "ID of the WAF WebACL"
}

output "waf_web_acl_arn" {
  value       = module.waf.web_acl_arn
  description = "ARN of the WAF WebACL"
}

output "waf_log_group_name" {
  value       = module.waf.log_group_name
  description = "Name of the CloudWatch Log Group for WAF logs"
}

output "waf_blocked_requests_alarm_arn" {
  value       = module.waf.blocked_requests_alarm_arn
  description = "ARN of the CloudWatch Alarm for blocked requests"
}
