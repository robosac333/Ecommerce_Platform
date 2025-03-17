variable "vpc_name" {}
variable "subnet_id" {
  description = "ID of the public subnet where the EC2 instance will be placed"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

# ================================================================

# Security Group for EC2 instance
resource "aws_security_group" "ecommerce_sg" {
  name        = "${var.vpc_name}-security-group"
  description = "Allow HTTP and SSH traffic"
  vpc_id      = var.vpc_id

  # SSH access
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "SSH access"
  }

  # HTTP access
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access"
  }

  # HTTPS access
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS access"
  }

  # Outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "ecommerce-sg"
    Project = "ecommerce-app"
  }
}

# EC2 Instance
resource "aws_instance" "ecommerce_instance" {
  ami                    = "ami-0d7de881073777ccd"  # Update to new AMI
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.ecommerce_sg.id]
  key_name               = "midterm"
  subnet_id              = var.subnet_id
  associate_public_ip_address = true

  tags = {
    Name = "ecommerce-instance"
    Project = "ecommerce-app"
  }

  # User data script to install dependencies and clone the repository
  user_data = <<-EOF
  #!/bin/bash
  set -e  # Exit on error
  exec > >(tee /var/log/user-data.log) 2>&1  # Log everything

  # Update EC2 instance
  sudo apt update -y

  # Install MySQL client
  sudo apt install mysql-client -y

  # Install Apache2 Web Server
  sudo apt install apache2 -y
    
  # Check UFW Firewall Application Profiles
  sudo ufw app list

  # Start the Apache2 service (fix the syntax)
  sudo systemctl start apache2

  # Install PHP and Required Modules
  sudo apt install php libapache2-mod-php php-mysql -y

  # Configure Apache to Prioritize index.php
  sudo sh -c 'echo "<IfModule mod_dir.c>
    DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
  </IfModule>" > /etc/apache2/mods-enabled/dir.conf'

  # Restart Apache2 Service
  sudo systemctl restart apache2

  # Clone directly to web root instead of copying
  cd /var/www/html
  sudo rm -rf index.html
  sudo git clone https://github.com/edaviage/818N-E_Commerce_Application.git .
  sudo mv /var/www/html/818N-E_Commerce_Application/* /var/www/html/
  sudo mv /var/www/html/818N-E_Commerce_Application/.* /var/www/html/ 2>/dev/null || true
  sudo rmdir /var/www/html/818N-E_Commerce_Application

  # Set proper permissions
  sudo chown -R www-data:www-data /var/www/html/
  sudo chmod -R 755 /var/www/html/

  # Restart Apache
  sudo systemctl restart apache2
  EOF

  # Make sure the instance has an Elastic IP (optional but recommended)
  root_block_device {
    volume_size = 8
    volume_type = "gp2"
    delete_on_termination = true
  }
}

# Elastic IP for the EC2 instance (optional but recommended)
resource "aws_eip" "ecommerce_eip" {
  instance = aws_instance.ecommerce_instance.id
  domain   = "vpc"

  tags = {
    Name = "ecommerce-eip"
    Project = "ecommerce-app"
  }
}

# ================================================================

# Output the public IP and DNS of the instance
output "instance_public_ip" {
  value       = aws_eip.ecommerce_eip.public_ip
  description = "The public IP address of the ecommerce instance"
}

output "instance_public_dns" {
  value       = aws_instance.ecommerce_instance.public_dns
  description = "The public DNS of the ecommerce instance"
}

output "website_url" {
  value       = "http://${aws_eip.ecommerce_eip.public_ip}"
  description = "URL to access the ecommerce website"
}

output "security_group_id" {
  value       = aws_security_group.ecommerce_sg.id
  description = "The ID of the EC2 security group"
}
