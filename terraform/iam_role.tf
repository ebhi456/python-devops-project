data "aws_iam_policy" "ebs_csi" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

data "aws_iam_openid_connect_provider" "eks" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

locals {
  oidc_provider = replace(
    aws_eks_cluster.eks.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
}

data "aws_iam_policy_document" "ebs_csi_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.eks.arn]
    }

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_provider}:sub"
      values   = [
        "system:serviceaccount:kube-system:ebs-csi-controller-sa"
      ]
    }
  }
}

resource "aws_iam_role" "ebs_csi" {
  name = "AmazonEKS_EBS_CSI_DriverRole"

  assume_role_policy = data.aws_iam_policy_document.ebs_csi_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  role       = aws_iam_role.ebs_csi.name
  policy_arn = data.aws_iam_policy.ebs_csi.arn
}