vpc_cidr           = "10.0.0.0/16"
vpc_name           = "ecommerce-vpc"
cidr_public_subnet = ["10.0.1.0/24"]
# eu_availability_zone = ["us-east-1a"]
# cidr_private_subnet  = ["10.0.2.0/24"]
# cidr_public_subnet = ["10.0.1.0/24", "10.0.2.0/24"]
cidr_private_subnet  = ["10.0.3.0/24", "10.0.4.0/24"]
eu_availability_zone = ["us-east-1a", "us-east-1b"]