variable "vpc_id"{
    description = "ID of the VPC"
    type        = string
}
variable "private_subnet_ids" {
    description = "List of private subnet IDs"
    type        = list(string)
}
variable "ec2_security_group_id" {
    description = "ID of the EC2 security group"
    type        = string
}
variable "db_username" {
    description = "Username for the database"
    type        = string
    default     = "admin"
    sensitive   = true
}
variable "db_password" {
    description = "Password for the database"
    type        = string
    sensitive   = true
}
variable "db_name" {
    description = "Name of the database"
    type        = string
    default     = "ecommercedb"
}
variable "storage_encrypted" {
    description = "Whether to encrypt the RDS storage"
    type        = bool
    default     = true
}
variable "kms_key_id" {
    description = "KMS key ID for RDS encryption"
    type        = string
    default     = null
}

# ================================================================

# RDS DB Subnet Group
resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "ecommerce-rds-subnet-group"
  subnet_ids = var.private_subnet_ids
  description = "Subnet group for RDS database"

  tags = {
    Name = "ecommerce-rds-subnet-group"
  }
}


# Security Group for RDS
resource "aws_security_group" "rds_sg" {
  name        = "rds-security-group"
  description = "Security group for RDS database"
  vpc_id      = var.vpc_id

  # Outbound internet access (for updates, etc.)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow outbound traffic for updates"
  }

  tags = {
    Name = "ecommerce-rds-sg"
    Project = "ecommerce-app"
  }
}

# Create a DB parameter group for SSL configuration
resource "aws_db_parameter_group" "mysql_ssl_params" {
  name        = "ecommerce-mysql-ssl-params"
  family      = "mysql8.0"
  description = "MySQL parameter group with SSL enabled"

  parameter {
    name  = "require_secure_transport"
    value = "ON"
    apply_method = "pending-reboot"
  }

  tags = {
    Name    = "ecommerce-mysql-ssl-params"
    Project = "ecommerce-app"
  }
}

# RDS Instance with SSL enabled
resource "aws_db_instance" "ecommerce_db" {
  allocated_storage      = 20
  storage_type          = "gp2"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  db_name              = var.db_name
  username             = var.db_username
  password             = var.db_password
  parameter_group_name = aws_db_parameter_group.mysql_ssl_params.name
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  publicly_accessible  = false
  storage_encrypted    = var.storage_encrypted
  kms_key_id           = var.kms_key_id

  # Enable SSL/TLS
  ca_cert_identifier    = "rds-ca-rsa2048-g1"

  tags = {
    Name    = "ecommerce-db"
    Project = "ecommerce-app"
  }
}

# ================================================================

# Outputs
output "rds_endpoint" {
  value       = aws_db_instance.ecommerce_db.endpoint
  description = "The connection endpoint for the RDS database"
}

output "db_name" {
  value       = aws_db_instance.ecommerce_db.db_name
  description = "The name of the database"
}

# Add an output for the security group ID
output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
  description = "The ID of the RDS security group"
}

output "rds_ssl_enabled" {
  value       = true
  description = "Indicates that SSL is enabled for RDS connections"
}

output "rds_ca_cert_identifier" {
  value       = aws_db_instance.ecommerce_db.ca_cert_identifier
  description = "The CA certificate identifier used for RDS SSL connections"
}
