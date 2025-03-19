variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "public_subnet_ids" {
  description = "IDs of public subnets"
  type        = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of private subnets"
  type        = list(string)
}

variable "instance_security_group_id" {
  description = "ID of the EC2 instance security group"
  type        = string
}

variable "instance_id" {
  description = "ID of the EC2 instance"
  type        = string
}
