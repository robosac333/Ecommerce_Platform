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
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ecommerce-alb-sg"
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
}

# ALB Listener
resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.ecommerce_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecommerce_tg.arn
  }
}