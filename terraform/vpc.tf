resource "aws_vpc" "employee_api_vpc" {
  cidr_block = var.vpc_cidr_block

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "${var.project_name}-vpc"
    project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.employee_api_vpc.id
  cidr_block              = var.public_subnet_cidr_block
  map_public_ip_on_launch = true

  tags = {
    Name        = "${var.project_name}-public-subnet"
    project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_internet_gateway" "employee_api_igw" {
  vpc_id = aws_vpc.employee_api_vpc.id

  tags = {
    Name        = "${var.project_name}-igw"
    project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.employee_api_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.employee_api_igw.id
  }

  tags = {
    Name        = "${var.project_name}-public-rt"
    project     = var.project_name
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}


