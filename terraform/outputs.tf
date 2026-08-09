output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.employee_api_vpc.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.employee_api.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.employee_api.repository_url
}