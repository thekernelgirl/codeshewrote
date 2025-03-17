# main.tf

provider "aws" {
  region = "us-west-2"  # Update with your desired region
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
}

variable "node_instance_type" {
  description = "Instance type for the EKS worker nodes"
  default     = "t3.medium"
}

variable "desired_capacity" {
  description = "Desired number of EC2 instances in the node group"
  default     = 2
}

variable "max_capacity" {
  description = "Maximum number of EC2 instances in the node group"
  default     = 3
}

variable "min_capacity" {
  description = "Minimum number of EC2 instances in the node group"
  default     = 1
}

variable "ecr_repository_name" {
  description = "Name of the ECR repository"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.21"

  vpc_config {
    subnet_ids         = aws_subnet.eks_subnets[*].id
    security_group_ids = [aws_security_group.eks_cluster_sg.id]
  }

  depends_on = [aws_iam_role_policy_attachment.eks_cluster_attachment]
}

resource "aws_iam_role" "eks_cluster_role" {
  name               = "eks-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy_attachment" "eks_cluster_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "${var.cluster_name}-workers"
  node_role_arn   = aws_iam_role.eks_node_role.arn

  scaling_config {
    desired_size = var.desired_capacity
    max_size     = var.max_capacity
    min_size     = var.min_capacity
  }

  remote_access {
    ec2_ssh_key = "your-key-pair-name"
  }

  subnet_ids = aws_subnet.eks_subnets[*].id
}

resource "aws_iam_role" "eks_node_role" {
  name               = "eks-node-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_ecr_repository" "ecr_repository" {
  name = var.ecr_repository_name
}

