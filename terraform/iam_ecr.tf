resource "aws_iam_role_policy_attachment" "employee_api_ecr_readonly_policy_attachment" {
  role       = aws_iam_role.employee_api_ec2_role.name
  policy_arn = aws_iam_policy.employee_api_ec2_role_policy.arn
}