# main.tf

provider "aws" {
  region = "us-west-2"  # Update with your desired region
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"  # Update with the path to your kubeconfig file
  }
}

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
}

variable "prometheus_namespace" {
  description = "Namespace for Prometheus installation"
  default     = "monitoring"  # Update with your desired namespace
}

resource "helm_release" "prometheus" {
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = var.prometheus_namespace
  version    = "14.1.0"  # Update with the desired Prometheus chart version

  values = [
    file("${path.module}/values.yaml")
  ]
}

