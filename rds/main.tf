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

# # RDS Instance 
# resource "aws_db_instance" "ecommerce_db" {
#   allocated_storage      = 20
#   storage_type           = "gp2"
#   engine                 = "mysql"
#   engine_version         = "8.0"
#   instance_class         = "db.t3.micro"
#   db_name                = "ecommercedb"
#   username               = "admin" 
#   password               = "Password123"
#   parameter_group_name   = "default.mysql8.0"
#   db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   skip_final_snapshot    = true
#   publicly_accessible    = false

#   tags = {
#     Name    = "ecommerce-db"
#     Project = "ecommerce-app"
#   }
# }

# ================================================================

# Outputs
# output "rds_endpoint" {
#   value       = aws_db_instance.ecommerce_db.endpoint
#   description = "The connection endpoint for the RDS database"
# }

# output "db_name" {
#   value       = aws_db_instance.ecommerce_db.db_name
#   description = "The name of the database"
# }

# Add an output for the security group ID
output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
  description = "The ID of the RDS security group"
}