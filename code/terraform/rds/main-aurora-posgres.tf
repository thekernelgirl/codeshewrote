# main.tf

provider "aws" {
  region = "us-east-1"  # Update with your desired region
}

variable "db_name" {
  description = "Name of the database"
}

variable "db_username" {
  description = "Username for the database"
}

variable "db_password" {
  description = "Password for the database"
}

variable "db_instance_class" {
  description = "Instance class for the Aurora cluster instances"
  default     = "db.r5.large"  # Update with your desired instance class
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  default     = "11.10"  # Update with your desired engine version
}

variable "engine_mode" {
  description = "Aurora PostgreSQL engine mode"
  default     = "provisioned"  # Update with "serverless" if using Aurora Serverless
}

variable "allocated_storage" {
  description = "The allocated storage size for the Aurora cluster (in gigabytes)"
  default     = 20  # Update with your desired storage size
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

resource "aws_rds_cluster" "aurora_cluster" {
  cluster_identifier          = "my-aurora-cluster"
  engine                      = "aurora-postgresql"
  engine_version              = var.engine_version
  engine_mode                 = var.engine_mode
  database_name               = var.db_name
  master_username             = var.db_username
  master_password             = var.db_password
  backup_retention_period     = 7  # Update with your desired backup retention period (in days)
  preferred_backup_window     = "03:00-04:00"  # Update with your desired backup window
  db_subnet_group_name        = var.db_subnet_group_name
  vpc_security_group_ids      = var.vpc_security_group_ids
  skip_final_snapshot         = true  # Update accordingly
}

resource "aws_rds_cluster_instance" "aurora_instances" {
  count               = 2  # Number of instances in the cluster
  cluster_identifier  = aws_rds_cluster.aurora_cluster.id
  identifier          = "aurora-instance-${count.index}"
  instance_class      = var.db_instance_class
}

