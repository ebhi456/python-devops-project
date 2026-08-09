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

variable "ec2_instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ec2_root_volume_size" {
  description = "EC2 root volume size"
  type        = number
  default     = 20
}

variable "ec2_root_volume_type" {
  description = "EC2 root volume type"
  type        = string
  default     = "gp2"
}