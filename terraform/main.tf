resource "aws_ecr_repository" "employee_api" {
  name = "${var.project_name}-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  force_delete = true

  tags = {
    Name        = "${var.project_name}-app"
    Environment = "dev"
    ManagedBy   = "Terraform"
  }
  
}
