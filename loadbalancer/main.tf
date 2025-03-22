# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "ecommerce-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP traffic from internet"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS traffic from internet"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ecommerce-alb-sg"
    Project = "ecommerce-app"
  }
}

# Create an ACM certificate for the domain with explicit key configuration
resource "aws_acm_certificate" "domain_cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["www.${var.domain_name}"]
  validation_method         = "DNS"
  
  # Specify key algorithm and size to ensure they're supported
  key_algorithm             = "RSA_2048"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name    = "ecommerce-domain-cert"
    Project = "ecommerce-app"
  }
}

# Get the Route 53 hosted zone for the domain
# Make sure the hosted zone exists in your AWS account
data "aws_route53_zone" "domain_zone" {
  name         = var.domain_name
  private_zone = false
}

# Create Route 53 records for certificate validation
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.domain_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.domain_zone.zone_id
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.domain_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Create Route 53 record for the ALB
resource "aws_route53_record" "alb_record" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.ecommerce_lb.dns_name
    zone_id                = aws_lb.ecommerce_lb.zone_id
    evaluate_target_health = true
  }
}

# Create www subdomain record
resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.domain_zone.zone_id
  name    = "www.${var.domain_name}"
  type    = "A"

  alias {
    name                   = aws_lb.ecommerce_lb.dns_name
    zone_id                = aws_lb.ecommerce_lb.zone_id
    evaluate_target_health = true
  }
}


# Application Load Balancer
resource "aws_lb" "ecommerce_lb" {
  name               = "ecommerce-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.public_subnet_ids

  tags = {
    Name = "ecommerce-lb"
  }
}

# Target Group
resource "aws_lb_target_group" "ecommerce_tg" {
  name     = "ecommerce-targetgroup"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
}

// Manually attach existing EC2 instance to the target group
resource "aws_lb_target_group_attachment" "existing_instance" {
  target_group_arn = aws_lb_target_group.ecommerce_tg.arn
  target_id        = var.instance_id
  port             = 80
}

// Create AMI from existing instance
resource "aws_ami_from_instance" "ecommerce_ami" {
  name               = "ecommerce-ami"
  source_instance_id = var.instance_id

  tags = {
    Name = "ecommerce-ami"
  }
}

# Launch Template using the AMI created from existing instance
resource "aws_launch_template" "ecommerce_template" {
  name = "ecommerce-template"

  image_id      = aws_ami_from_instance.ecommerce_ami.id
  instance_type = "t2.micro"

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.instance_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "ecommerce-asg-instance"
      Project = "ecommerce-app"
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "ecommerce_asg" {
  name                      = "ecommerce-asg"
  desired_capacity          = 1
  max_size                  = 3
  min_size                  = 1
  target_group_arns         = [aws_lb_target_group.ecommerce_tg.arn]
  vpc_zone_identifier       = var.public_subnet_ids
  health_check_type         = "ELB"
  health_check_grace_period = 300
  
  launch_template {
    id      = aws_launch_template.ecommerce_template.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "ecommerce-asg-instance"
    propagate_at_launch = true
  }

  # Enable metrics collection for the ASG
  metrics_granularity = "1Minute"
  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances"
  ]
}

# Scale Out Policy (Add instances)
resource "aws_autoscaling_policy" "scale_out" {
  name                   = "ecommerce-scale-out-policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecommerce_asg.name
}

# Scale In Policy (Remove instances)
resource "aws_autoscaling_policy" "scale_in" {
  name                   = "ecommerce-scale-in-policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.ecommerce_asg.name
}

# HTTPS Listener
resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.ecommerce_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.domain_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecommerce_tg.arn
  }
}

# HTTP Listener - Redirect to HTTPS
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ecommerce_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
