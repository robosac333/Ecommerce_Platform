# Ecommerce_Platform

Hosting an Ecommerce platform with security protocol as a IaaC (Infrastructure as Code) on Hashicorp Terraform.

## Architecture

This project deploys a scalable ecommerce platform on AWS using Terraform with the following components:

- **Networking**: VPC, public and private subnets, internet gateway, route tables
- **EC2**: Web server instances with Apache and PHP
- **RDS**: MySQL database for the ecommerce application
- **Load Balancer**: Application Load Balancer for distributing traffic
- **Auto Scaling**: Auto Scaling Group to handle varying loads
- **CloudWatch**: Alarms to trigger scaling events based on metrics
- **WAF**: Web Application Firewall to protect against SQL Injection and XSS attacks
- **SSL/TLS**: HTTPS for secure client-server communication and SSL for database connections

## Modules

### Networking

Sets up the VPC, subnets, internet gateway, and route tables.

### EC2

Deploys EC2 instances with the necessary software for the ecommerce application.

### RDS

Sets up a MySQL database for the ecommerce application.

### Load Balancer

Configures an Application Load Balancer and Auto Scaling Group.

### CloudWatch

Sets up CloudWatch alarms to trigger scaling events based on various metrics:

- CPU utilization (high and low)
- Network traffic (in and out)
- Request count
- Response time

### WAF

Configures AWS Web Application Firewall (WAF) to protect the application from common web exploits:

- SQL Injection protection using AWS Managed Rules
- Cross-Site Scripting (XSS) protection using AWS Managed Rules
- Rate-based rules to prevent DDoS attacks
- Custom rules to block known bad bots
- Logging of blocked requests to CloudWatch Logs
- CloudWatch alarms for monitoring blocked requests

### SSL/TLS Encryption

Implements secure data transmission using:

- **HTTPS**: AWS Certificate Manager (ACM) certificate with DNS validation for HTTPS communication
- **Domain Integration**: Proper domain name configuration with Route 53
- **HTTP to HTTPS Redirection**: Automatically redirects HTTP traffic to HTTPS
- **RDS SSL**: Enforces SSL connections between the application and the MySQL database
- **Parameter Group**: Custom DB parameter group with `require_secure_transport=ON`

## Auto Scaling

The platform automatically scales based on the following metrics:

- High CPU utilization (> 70%) triggers scale out
- Low CPU utilization (< 30%) triggers scale in
- High network traffic triggers scale out
- High request count triggers scale out
- High response time triggers scale out

A CloudWatch dashboard is also created to monitor these metrics.

## Getting Started

1. Clone this repository
2. Update `terraform.tfvars` with your desired values
3. Run `terraform init` to initialize the project
4. Run `terraform plan` to see the changes that will be made
5. Run `terraform apply` to deploy the infrastructure

## Outputs

- `instance_public_ip`: Public IP of the EC2 instance
- `website_url`: URL to access the ecommerce website
- `alb_dns_name`: DNS name of the Application Load Balancer
- `high_cpu_alarm_arn`: ARN of the high CPU utilization alarm
- `low_cpu_alarm_arn`: ARN of the low CPU utilization alarm
- `autoscaling_group_name`: Name of the Auto Scaling Group
- `cloudwatch_dashboard_arn`: ARN of the CloudWatch dashboard
- `waf_web_acl_id`: ID of the WAF WebACL
- `waf_web_acl_arn`: ARN of the WAF WebACL
- `waf_log_group_name`: Name of the CloudWatch Log Group for WAF logs
- `waf_blocked_requests_alarm_arn`: ARN of the CloudWatch Alarm for blocked requests
- `https_listener_arn`: ARN of the HTTPS listener
- `acm_certificate_arn`: ARN of the ACM certificate used for HTTPS
- `rds_ssl_enabled`: Indicates that SSL is enabled for RDS connections
- `rds_ca_cert_identifier`: The CA certificate identifier used for RDS SSL connections
- `domain_name`: Domain name used for the website
- `www_domain_name`: WWW subdomain used for the website
- `route53_zone_id`: Route 53 hosted zone ID for the domain
