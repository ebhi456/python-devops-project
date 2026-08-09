variable "aws_region" {
  description = "aws region definition"
  type = string
  default = "us-east-1"
}

variable "project_name" {
  description = "project name definition"
  type = string
  #default = "python-devops-project"
}

variable "vpc_cidr_block" {
  description = "VPC CIDR block definition"
  type = string
  #default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "Public Subnet CIDR block definition"
  type = string
  #default = "10.0.1.0/24"
}

