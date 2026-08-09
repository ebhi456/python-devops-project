resource "aws_iam_instance_profile" "employee_api_ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.employee_api_ec2_role.name
}