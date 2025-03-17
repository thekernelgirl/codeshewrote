# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "cluster_identifier" {
  description = "Name of the Redshift cluster"
}

variable "node_type" {
  description = "The node type to be provisioned for the Redshift cluster"
  default     = "dc2.large"  # Update with your desired node type
}

variable "number_of_nodes" {
  description = "The number of compute nodes in the Redshift cluster"
  default     = 2  # Update with your desired number of nodes
}

variable "master_username" {
  description = "Username for the master user"
}

variable "master_password" {
  description = "Password for the master user"
}

variable "db_name" {
  description = "Name of the default database created in the Redshift cluster"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs for the Redshift cluster"
  type        = list(string)
}

variable "encrypted" {
  description = "Whether the Redshift cluster should be encrypted or not"
  default     = true  # Update according to your encryption preference
}

variable "snapshot_identifier" {
  description = "The identifier for the snapshot to restore the Redshift cluster from"
  default     = ""  # Leave empty if not restoring from a snapshot
}

resource "aws_redshift_cluster" "redshift_cluster" {
  cluster_identifier         = var.cluster_identifier
  node_type                  = var.node_type
  number_of_nodes            = var.number_of_nodes
  master_username            = var.master_username
  master_password            = var.master_password
  db_name                    = var.db_name
  cluster_subnet_group_name  = "default"  # Update with your subnet group name
  vpc_security_group_ids     = var.vpc_security_group_ids
  encrypted                  = var.encrypted
  snapshot_identifier        = var.snapshot_identifier

  # Concurrency Scaling Configuration
  enable_concurrency_scaling = true
  node_type                  = "dc2.large"  # Update with your desired node type for concurrency scaling
  number_of_nodes            = 2            # Update with your desired number of nodes for concurrency scaling

  # Cross-Region Snapshot Copy Configuration
  cluster_parameter_group_name = "default.redshift-1.0"
  availability_zone            = "us-east-1a"  # Update with your desired availability zone
  port                         = 5439          # Update with your desired port
}

