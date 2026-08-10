terraform {
  required_version = "> 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "~> 3.5"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_eks_cluster" "employee_api" {
  name = aws_eks_cluster.employee_api.name
}

data "aws_eks_cluster_auth" "employee_api" {
  name = aws_eks_cluster.employee_api.name
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.employee_api.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.employee_api.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.employee_api.token
}

provider "helm" {
  kubernetes= {
    host                   = data.aws_eks_cluster.employee_api.endpoint
    cluster_ca_certificate = base64decode(
      data.aws_eks_cluster.employee_api.certificate_authority[0].data
    )
    token                  = data.aws_eks_cluster_auth.employee_api.token
  }
}