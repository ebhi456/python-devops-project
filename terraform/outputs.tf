output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.employee_api.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.employee_api.repository_url
}


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

