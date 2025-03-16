variable "vpc_cidr" {}
variable "vpc_name" {}
variable "cidr_public_subnet" {}
variable "eu_availability_zone" {}
variable "cidr_private_subnet" {}

# ================================================================

# Setup VPC
resource "aws_vpc" "ecommerce_project_vpc_us_east_1" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# Setup public subnet
resource "aws_subnet" "ecommerce_project_public_subnets" {
  count             = length(var.cidr_public_subnet)
  vpc_id            = aws_vpc.ecommerce_project_vpc_us_east_1.id
  cidr_block        = element(var.cidr_public_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "ecommerce-public-subnet-${count.index + 1}"
  }
}

# Setup private subnet
resource "aws_subnet" "dev_proj_1_private_subnets" {
  count             = length(var.cidr_private_subnet)
  vpc_id            = aws_vpc.ecommerce_project_vpc_us_east_1.id
  cidr_block        = element(var.cidr_private_subnet, count.index)
  availability_zone = element(var.eu_availability_zone, count.index)

  tags = {
    Name = "ecommerce-private-subnet-${count.index + 1}"
  }
}

# Setup Internet Gateway
resource "aws_internet_gateway" "dev_proj_1_public_internet_gateway" {
  vpc_id = aws_vpc.ecommerce_project_vpc_us_east_1.id
  tags = {
    Name = "ecommerce-1-igw"
  }
}

# Public Route Table
resource "aws_route_table" "dev_proj_1_public_route_table" {
  vpc_id = aws_vpc.ecommerce_project_vpc_us_east_1.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.dev_proj_1_public_internet_gateway.id
  }
  tags = {
    Name = "ecommerce-1-public-rt"
  }
}

# Public Route Table and Public Subnet Association
resource "aws_route_table_association" "dev_proj_1_public_rt_subnet_association" {
  count          = length(aws_subnet.ecommerce_project_public_subnets)
  subnet_id      = aws_subnet.ecommerce_project_public_subnets[count.index].id
  route_table_id = aws_route_table.dev_proj_1_public_route_table.id
}

# Private Route Table
resource "aws_route_table" "dev_proj_1_private_subnets" {
  vpc_id = aws_vpc.ecommerce_project_vpc_us_east_1.id
  #depends_on = [aws_nat_gateway.nat_gateway]
  tags = {
    Name = "ecommerce-1-private-rt"
  }
}

# Private Route Table and private Subnet Association
resource "aws_route_table_association" "dev_proj_1_private_rt_subnet_association" {
  count          = length(aws_subnet.dev_proj_1_private_subnets)
  subnet_id      = aws_subnet.dev_proj_1_private_subnets[count.index].id
  route_table_id = aws_route_table.dev_proj_1_private_subnets.id
}

# ================================================================

# Get outputs from your networking setup
output "private_subnet_ids" {
  value = aws_subnet.dev_proj_1_private_subnets.*.id
}

output "public_subnet_ids" {
  value = aws_subnet.ecommerce_project_public_subnets.*.id
}

output "ecommerce_vpc_id" {
  value = aws_vpc.ecommerce_project_vpc_us_east_1.id
}

output "ecommerce_public_subnets" {
  value = aws_subnet.ecommerce_project_public_subnets.*.id
}

output "public_subnet_cidr_block" {
  value = aws_subnet.ecommerce_project_public_subnets.*.cidr_block
}

output "public_subnet_id" {
  value = aws_subnet.ecommerce_project_public_subnets[0].id
  description = "ID of the first public subnet"
}