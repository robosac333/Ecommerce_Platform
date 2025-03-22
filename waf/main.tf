resource "aws_wafv2_web_acl" "ecommerce_waf" {
  name        = "ecommerce-waf-acl"
  description = "WAF WebACL for ecommerce application"
  scope       = "REGIONAL"

  default_action {
    allow {}
  }

  # AWS Managed Rule - Core rule set
  rule {
    name     = "AWS-AWSManagedRulesCommonRuleSet"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - SQL Injection rule set
  rule {
    name     = "AWS-AWSManagedRulesSQLiRuleSet"
    priority = 2

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # AWS Managed Rule - XSS rule set
  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 3

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule - Rate limiting
  rule {
    name     = "RateLimitRule"
    priority = 4

    action {
      block {}
    }

    statement {
      rate_based_statement {
        limit              = var.rate_limit
        aggregate_key_type = "IP"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "RateLimitRule"
      sampled_requests_enabled   = true
    }
  }

  # Custom rule - Block specific user agents
  rule {
    name     = "BlockBadBots"
    priority = 5

    action {
      block {}
    }

    statement {
      byte_match_statement {
        field_to_match {
          single_header {
            name = "user-agent"
          }
        }
        positional_constraint = "CONTAINS"
        search_string         = "bad-bot"
        
        # AWS WAFv2 requires multiple text_transformation blocks
        text_transformation {
          priority = 0
          type     = "LOWERCASE"
        }
        
        # Adding a second text_transformation block to fix "Insufficient text_transformation blocks" error
        text_transformation {
          priority = 1
          type     = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "BlockBadBots"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "ecommerce-waf-acl"
    sampled_requests_enabled   = true
  }

  tags = var.tags
}

# Create CloudWatch Log Group for WAF logs
resource "aws_cloudwatch_log_group" "waf_logs" {
  name              = "/aws/waf/ecommerce-waf-logs"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

# Create Kinesis Firehose for WAF logs
resource "aws_kinesis_firehose_delivery_stream" "waf_logs" {
  name        = "aws-waf-logs-ecommerce"
  destination = "extended_s3"
  
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.waf_logs.arn
    prefix     = "waf-logs/"
    
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.waf_logs.name
      log_stream_name = "S3Delivery"
    }
  }
  
  tags = var.tags
}

# S3 bucket for WAF logs
resource "aws_s3_bucket" "waf_logs" {
  bucket = "ecommerce-waf-logs-${var.aws_region}"
  tags   = var.tags
}

# IAM role for Firehose
resource "aws_iam_role" "firehose_role" {
  name = "ecommerce-firehose-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
  
  tags = var.tags
}

# IAM policy for Firehose
resource "aws_iam_role_policy" "firehose_policy" {
  name   = "ecommerce-firehose-policy"
  role   = aws_iam_role.firehose_role.id
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.waf_logs.arn,
          "${aws_s3_bucket.waf_logs.arn}/*"
        ]
      },
      {
        Action = [
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.waf_logs.arn}:*"
      }
    ]
  })
}

# Configure WAF logging
resource "aws_wafv2_web_acl_logging_configuration" "waf_logging" {
  log_destination_configs = [aws_kinesis_firehose_delivery_stream.waf_logs.arn]
  resource_arn            = aws_wafv2_web_acl.ecommerce_waf.arn
  
  redacted_fields {
    single_header {
      name = "authorization"
    }
  }
}

# Associate WAF WebACL with ALB
resource "aws_wafv2_web_acl_association" "alb_association" {
  resource_arn = var.alb_arn
  web_acl_arn  = aws_wafv2_web_acl.ecommerce_waf.arn
}

# Create CloudWatch Metric Alarm for blocked requests
resource "aws_cloudwatch_metric_alarm" "waf_blocked_requests" {
  alarm_name          = "ecommerce-waf-blocked-requests"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "BlockedRequests"
  namespace           = "AWS/WAFV2"
  period              = 300
  statistic           = "Sum"
  threshold           = var.blocked_requests_threshold
  alarm_description   = "This metric monitors the number of requests blocked by WAF"
  
  dimensions = {
    WebACL = "ecommerce-waf-acl"
    Region = var.aws_region
    Rule   = "ALL"
  }
  
  alarm_actions = var.alarm_actions
  tags          = var.tags
}
