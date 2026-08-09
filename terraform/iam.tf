resource "aws_iam_role" "employee_api_ec2_role" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name        = "${var.project_name}-ec2-role"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
}

resource "aws_iam_policy" "employee_api_ec2_role_policy" {
  name        = "${var.project_name}-ec2-role-policy"
  description = "IAM policy for EC2 role to access ECR repository"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
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