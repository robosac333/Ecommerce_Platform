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

# Create a self-signed certificate for HTTPS
resource "aws_acm_certificate" "self_signed_cert" {
  private_key      = tls_private_key.private_key.private_key_pem
  certificate_body = tls_self_signed_cert.self_signed_cert.cert_pem

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "ecommerce-self-signed-cert"
    Project = "ecommerce-app"
  }
}

# Generate a private key for the self-signed certificate
resource "tls_private_key" "private_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Create a self-signed TLS certificate
resource "tls_self_signed_cert" "self_signed_cert" {
  private_key_pem = tls_private_key.private_key.private_key_pem

  subject {
    common_name  = "ecommerce-example.com"
    organization = "Ecommerce Example, Inc"
  }

  validity_period_hours = 8760 # 1 year

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
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
  certificate_arn   = aws_acm_certificate.self_signed_cert.arn

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
