# ============================================================
# EKS Managed Node Group
# ============================================================

resource "aws_eks_node_group" "employee_api" {
  cluster_name = aws_eks_cluster.employee_api.name

  node_group_name = "${var.project_name}-nodes"

  node_role_arn = aws_iam_role.eks_node_role.arn

  # Worker nodes run only in private subnets
  subnet_ids = aws_subnet.private[*].id

  instance_types = [
    "t3.medium"
  ]

  capacity_type = "ON_DEMAND"

  scaling_config {
    desired_size = 2
    min_size     = 1
    max_size     = 3
  }

  update_config {
    max_unavailable = 1
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_ecr_readonly_policy
  ]

  tags = {
    Name = "${var.project_name}-eks-node"
    
    "k8s.io/cluster-autoscaler/enabled" = "true"
    "k8s.io/cluster-autoscaler/${aws_eks_cluster.employee_api.name}" = "owned"
  }
}
