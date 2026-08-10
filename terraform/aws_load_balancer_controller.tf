############################################
## AWS Load Balancer Controller
############################################

locals {
  alb_controller_namespace     = "kube-system"
  alb_controller_service_account = "aws-load-balancer-controller"

  eks_oidc_issuer = replace(
    aws_eks_cluster.employee_api.identity[0].oidc[0].issuer,
    "https://",
    ""
  )
}

############################################
## IAM Policy
############################################

data "http" "aws_load_balancer_controller_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-aws-load-balancer-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = data.http.aws_load_balancer_controller_policy.response_body

  tags = {
    Name    = "${var.project_name}-aws-load-balancer-controller-policy"
    project = var.project_name
  }
}

############################################
## IAM Role
############################################

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-aws-load-balancer-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.eks.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "${local.eks_oidc_issuer}:aud" = "sts.amazonaws.com"

            "${local.eks_oidc_issuer}:sub" = "system:serviceaccount:${local.alb_controller_namespace}:${local.alb_controller_service_account}"
          }
        }
      }
    ]
  })

  tags = {
    Name    = "${var.project_name}-aws-load-balancer-controller-role"
    project = var.project_name
  }
}

############################################
## Attach IAM Policy
############################################

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

############################################
## Kubernetes Service Account
############################################

resource "kubernetes_service_account" "aws_load_balancer_controller" {
  metadata {
    name      = local.alb_controller_service_account
    namespace = local.alb_controller_namespace

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_load_balancer_controller.arn
    }

    labels = {
      "app.kubernetes.io/name" = "aws-load-balancer-controller"
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws_load_balancer_controller
  ]
}

############################################
## AWS Load Balancer Controller Helm Chart
############################################

resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = local.alb_controller_namespace
  version    = "1.14.0"

  set = {
    name  = "clusterName"
    value = aws_eks_cluster.employee_api.name
  }

  set = {
    name  = "serviceAccount.create"
    value = "false"
  }

  set = {
    name  = "region"
    value = var.aws_region
  }
}