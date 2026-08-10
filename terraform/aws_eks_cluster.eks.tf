resource "aws_eks_addon" "ebs_csi" {
  cluster_name = aws_eks_cluster.eks.name

  addon_name                  = "aws-ebs-csi-driver"
  addon_version               = "v1.63.1-eksbuild.1"
  service_account_role_arn    = aws_iam_role.ebs_csi.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [
    aws_iam_role_policy_attachment.ebs_csi
  ]
}