terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.24"
    }
  }

  cloud {
    organization = "Ecommerce_Deployment"
    workspaces {
      name = "Ecommerce_Platform"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

module "networking" {
  source               = "./networking"
  vpc_cidr             = var.vpc_cidr
  vpc_name             = var.vpc_name
  cidr_public_subnet   = var.cidr_public_subnet
  eu_availability_zone = var.eu_availability_zone
  cidr_private_subnet  = var.cidr_private_subnet
}

module "ec2" {
  source    = "./ec2"
  subnet_id = module.networking.public_subnet_id
  vpc_id    = module.networking.ecommerce_vpc_id
  vpc_name  = var.vpc_name
}

# Call the RDS module
module "rds" {
  source = "./rds" 

  vpc_id    = module.networking.ecommerce_vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ec2_security_group_id = module.ec2.security_group_id
  # db_username = "admin"
  # db_password = "YourStrongPasswordHere"  # Use AWS Secrets Manager in production
}

# Add the loadbalancer module
module "loadbalancer" {
  source = "./loadbalancer"
  
  vpc_id                    = module.networking.ecommerce_vpc_id
  public_subnet_ids         = module.networking.public_subnet_ids
  instance_security_group_id = module.ec2.security_group_id
}

# Create the security group rules AFTER both modules are created
resource "aws_security_group_rule" "ec2_to_rds" {
  type                     = "egress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.rds.rds_security_group_id
  security_group_id        = module.ec2.security_group_id
  description              = "Allow MySQL connections to RDS"
}

resource "aws_security_group_rule" "rds_from_ec2" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.ec2.security_group_id
  security_group_id        = module.rds.rds_security_group_id
  description              = "Allow MySQL connections from EC2 instances"
}

# ================================================================

# Output values from the module
output "instance_public_ip" {
  value = module.ec2.instance_public_ip
}

output "website_url" {
  value = module.ec2.website_url
}

# Add loadbalancer outputs
output "alb_dns_name" {
  value = module.loadbalancer.alb_dns_name
}