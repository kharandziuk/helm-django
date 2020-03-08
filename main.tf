variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "bucket_name" {
  default="sample"
}

variable "aws_region" {
  default = "us-west-2"
  type    = string
}

locals {
  application_k8s_namespace = "default"
}

provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

variable "cluster_name" {
  default = "terraform-eks-demo"
  type    = string
}


data "aws_eks_cluster" "cluster" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "cluster" {
  name = data.aws_eks_cluster.cluster.name
}

output "endpoint" {
  value = data.aws_eks_cluster.cluster.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = data.aws_eks_cluster.cluster.certificate_authority.0.data
}

output "identity-oidc-issuer" {
  value = "${data.aws_eks_cluster.cluster.identity.0.oidc.0.issuer}"
}

provider "kubernetes" {
  version                = "~>1.10.0"
  host                   = data.aws_eks_cluster.cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
  token                  = data.aws_eks_cluster_auth.cluster.token
  load_config_file       = false
}

provider "helm" {
  version                = "~>1.0.0"
  debug = true

  kubernetes {
    host = data.aws_eks_cluster.cluster.endpoint
    token = data.aws_eks_cluster_auth.cluster.token
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.cluster.certificate_authority.0.data)
    load_config_file = false
  }
}

resource "aws_ecr_repository" "backend" {
  name                 = "test-django-backend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
}


resource "helm_release" "backend" {
  name  = "test-backend"
  chart = "./backend/chart"

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "VALUE_TO_SET"
    value = "hey kapa"
  }

}

data "kubernetes_service" "example" {
  metadata {
    name = "${helm_release.backend.name}-chart"
  }
}

output "host-name" {
  value = "http://${data.kubernetes_service.example.load_balancer_ingress.0.hostname}"
}

output "build-backend-image" {
  value = "docker build -t ${aws_ecr_repository.backend.repository_url} ./backend && docker push ${aws_ecr_repository.backend.repository_url}"
}
