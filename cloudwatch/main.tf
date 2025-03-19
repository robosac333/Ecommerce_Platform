resource "aws_cloudwatch_metric_alarm" "high_cpu_utilization" {
  alarm_name          = "${var.prefix}-high-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.high_cpu_threshold
  alarm_description   = "This metric monitors EC2 CPU utilization exceeding threshold"
  alarm_actions       = [var.scale_out_policy_arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "low_cpu_utilization" {
  alarm_name          = "${var.prefix}-low-cpu-utilization"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.low_cpu_threshold
  alarm_description   = "This metric monitors EC2 CPU utilization below threshold"
  alarm_actions       = [var.scale_in_policy_arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_network_in" {
  count               = var.enable_network_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-high-network-in"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "NetworkIn"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.high_network_threshold
  alarm_description   = "This metric monitors EC2 network in exceeding threshold"
  alarm_actions       = [var.scale_out_policy_arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_network_out" {
  count               = var.enable_network_alarms ? 1 : 0
  alarm_name          = "${var.prefix}-high-network-out"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "NetworkOut"
  namespace           = "AWS/EC2"
  period              = var.period
  statistic           = "Average"
  threshold           = var.high_network_threshold
  alarm_description   = "This metric monitors EC2 network out exceeding threshold"
  alarm_actions       = [var.scale_out_policy_arn]
  dimensions = {
    AutoScalingGroupName = var.autoscaling_group_name
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_request_count" {
  count               = var.enable_request_count_alarm ? 1 : 0
  alarm_name          = "${var.prefix}-high-request-count"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "RequestCount"
  namespace           = "AWS/ApplicationELB"
  period              = var.period
  statistic           = "Sum"
  threshold           = var.high_request_count_threshold
  alarm_description   = "This metric monitors ALB request count exceeding threshold"
  alarm_actions       = [var.scale_out_policy_arn]
  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }
  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "high_target_response_time" {
  count               = var.enable_response_time_alarm ? 1 : 0
  alarm_name          = "${var.prefix}-high-response-time"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = var.evaluation_periods
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = var.period
  statistic           = "Average"
  threshold           = var.high_response_time_threshold
  alarm_description   = "This metric monitors ALB target response time exceeding threshold"
  alarm_actions       = [var.scale_out_policy_arn]
  dimensions = {
    LoadBalancer = var.load_balancer_arn_suffix
  }
  tags = var.tags
}

# Optional: Create a CloudWatch Dashboard for monitoring
resource "aws_cloudwatch_dashboard" "main" {
  count          = var.create_dashboard ? 1 : 0
  dashboard_name = "${var.prefix}-dashboard"
  
  dashboard_body = <<EOF
{
  "widgets": [
    {
      "type": "metric",
      "x": 0,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/EC2", "CPUUtilization", "AutoScalingGroupName", "${var.autoscaling_group_name}", { "label": "CPU Utilization" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "title": "EC2 CPU Utilization"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 0,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/EC2", "NetworkIn", "AutoScalingGroupName", "${var.autoscaling_group_name}", { "label": "Network In" } ],
          [ "AWS/EC2", "NetworkOut", "AutoScalingGroupName", "${var.autoscaling_group_name}", { "label": "Network Out" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "title": "EC2 Network Traffic"
      }
    },
    {
      "type": "metric",
      "x": 0,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "RequestCount", "LoadBalancer", "${var.load_balancer_arn_suffix}", { "label": "Request Count" } ]
        ],
        "period": 300,
        "stat": "Sum",
        "region": "${var.aws_region}",
        "title": "ALB Request Count"
      }
    },
    {
      "type": "metric",
      "x": 12,
      "y": 6,
      "width": 12,
      "height": 6,
      "properties": {
        "metrics": [
          [ "AWS/ApplicationELB", "TargetResponseTime", "LoadBalancer", "${var.load_balancer_arn_suffix}", { "label": "Response Time" } ]
        ],
        "period": 300,
        "stat": "Average",
        "region": "${var.aws_region}",
        "title": "ALB Response Time"
      }
    }
  ]
}
EOF
}
