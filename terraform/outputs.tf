output "ecr_repository_name" {
  description = "ECR repository name"
  value       = aws_ecr_repository.employee_api.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.employee_api.repository_url
}


output "ec2_role_name" {
  description = "Name of the IAM role for EC2"
  value       = aws_iam_role.employee_api_ec2_role.name
}