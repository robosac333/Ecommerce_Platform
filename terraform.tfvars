vpc_cidr           = "10.0.0.0/16"
vpc_name           = "ecommerce-vpc"
# cidr_public_subnet = ["10.0.1.0/24"]
# eu_availability_zone = ["us-east-1a"]
# cidr_private_subnet  = ["10.0.2.0/24"]
cidr_public_subnet = ["10.0.1.0/24", "10.0.2.0/24"]
cidr_private_subnet  = ["10.0.3.0/24", "10.0.4.0/24"]
eu_availability_zone = ["us-east-1a", "us-east-1b"]

# KMS key for RDS encryption
kms_key_id = "arn:aws:kms:us-east-1:242201279990:key/1ea1e133-7426-4a76-94c6-c7b105b0823e"

# Database configuration
# NOTE: In a production environment, these should be stored in a secure location
# and not in version control
db_username = "admin"
db_password = "Password123"
db_name     = "ecommercedb"
