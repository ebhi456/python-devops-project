output "vpc_id" {
  description = "employee api vpc id"
  value = aws_vpc.employee_api_vpc.id
}

output "public_subnet_id" {
  description = "employee api public subnet id"
  value = aws_subnet.public.id
}

output "security_group_id" {
  description = "employee api security group id"
  value = aws_security_group.employee_api_sg.id
}