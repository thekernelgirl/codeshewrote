# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "cluster_name" {
  description = "Name of the ElastiCache Redis cluster"
}

variable "engine_version" {
  description = "Redis engine version"
  default     = "5.0.6"  # Update with your desired Redis engine version
}

variable "node_type" {
  description = "The compute and memory capacity of the nodes in the cluster"
  default     = "cache.t2.micro"  # Update with your desired node type
}

variable "num_cache_nodes" {
  description = "The number of cache nodes in the cluster"
  default     = 1  # Update with your desired number of cache nodes
}

variable "subnet_group_name" {
  description = "Name of the subnet group for the ElastiCache Redis cluster"
}

variable "security_group_ids" {
  description = "List of security group IDs for the ElastiCache Redis cluster"
  type        = list(string)
}

resource "aws_elasticache_cluster" "redis_cluster" {
  cluster_id           = var.cluster_name
  engine_version       = var.engine_version
  node_type            = var.node_type
  num_cache_nodes      = var.num_cache_nodes
  cluster_subnet_group_name = var.subnet_group_name
  security_group_ids   = var.security_group_ids
}

