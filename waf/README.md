# AWS WAF Module

This module configures AWS Web Application Firewall (WAF) for the e-commerce application to protect against common web exploits such as SQL Injection and Cross-Site Scripting (XSS) attacks.

## Features

- Implements AWS Managed Rules for common web exploits
- Configures SQL Injection protection
- Configures Cross-Site Scripting (XSS) protection
- Implements rate-based rules to prevent DDoS attacks
- Blocks known bad bots
- Logs blocked requests to CloudWatch Logs
- Monitors WAF metrics with CloudWatch alarms

## Usage

```hcl
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
```

## AWS Managed Rules

This module implements the following AWS Managed Rules:

1. **AWSManagedRulesCommonRuleSet**: Provides protection against common web exploits
2. **AWSManagedRulesSQLiRuleSet**: Provides protection against SQL injection attacks
3. **AWSManagedRulesKnownBadInputsRuleSet**: Provides protection against known attack patterns, including XSS

## Custom Rules

In addition to AWS Managed Rules, this module implements the following custom rules:

1. **Rate Limiting Rule**: Limits the number of requests from a single IP address to prevent DDoS attacks
2. **Bad Bot Blocking Rule**: Blocks requests from known bad bots based on user-agent strings

## CloudWatch Monitoring

The module configures the following CloudWatch resources:

1. **Log Group**: Stores WAF logs for analysis
2. **Metric Alarm**: Triggers when the number of blocked requests exceeds a threshold

## Inputs

| Name                       | Description                                                                      | Type         | Default                       | Required |
| -------------------------- | -------------------------------------------------------------------------------- | ------------ | ----------------------------- | -------- |
| alb_arn                    | ARN of the Application Load Balancer to associate with the WAF WebACL            | string       | n/a                           | yes      |
| aws_region                 | AWS region where resources will be created                                       | string       | "us-east-1"                   | no       |
| rate_limit                 | Maximum number of requests allowed in a 5-minute period from a single IP address | number       | 2000                          | no       |
| log_retention_days         | Number of days to retain WAF logs in CloudWatch                                  | number       | 30                            | no       |
| blocked_requests_threshold | Threshold for the number of blocked requests to trigger an alarm                 | number       | 100                           | no       |
| alarm_actions              | List of ARNs to notify when the blocked requests alarm is triggered              | list(string) | []                            | no       |
| tags                       | Tags to apply to all resources                                                   | map(string)  | { Project = "ecommerce-app" } | no       |

## Outputs

| Name                       | Description                                      |
| -------------------------- | ------------------------------------------------ |
| web_acl_id                 | ID of the WAF WebACL                             |
| web_acl_arn                | ARN of the WAF WebACL                            |
| web_acl_name               | Name of the WAF WebACL                           |
| log_group_name             | Name of the CloudWatch Log Group for WAF logs    |
| log_group_arn              | ARN of the CloudWatch Log Group for WAF logs     |
| blocked_requests_alarm_arn | ARN of the CloudWatch Alarm for blocked requests |

## Viewing WAF Logs

WAF logs are stored in CloudWatch Logs. You can view them in the AWS Management Console:

1. Go to CloudWatch > Log Groups
2. Find the log group named `/aws/waf/ecommerce-waf-logs`
3. Click on the log group to view the log streams

## Analyzing Blocked Requests

To analyze blocked requests:

1. Go to CloudWatch > Dashboards
2. Open the `ecommerce-dashboard`
3. View the WAF metrics widgets to see blocked requests by rule type
