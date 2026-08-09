resource "aws_iam_policy" "emmployee_api_ec2_role_policy" {
  name        = "${var.project_name}-ec2-role-policy"
  description = "IAM policy for EC2 role to access ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"

        principal = {
          Service = "ec2.amazonaws.com"
        }
        action = "sts:AssumeRole"
        
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role-policy"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
  
}