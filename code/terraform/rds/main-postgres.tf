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
  description = "Instance class for the RDS instance"
  default     = "db.t2.micro"  # Update with your desired instance class
}

variable "allocated_storage" {
  description = "The allocated storage size for the RDS instance (in gigabytes)"
  default     = 20  # Update with your desired storage size
}

variable "db_subnet_group_name" {
  description = "Name of the DB subnet group"
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs"
  type        = list(string)
}

resource "aws_db_instance" "postgresql_instance" {
  identifier             = "mypostgresinstance"
  allocated_storage      = var.allocated_storage
  storage_type           = "gp2"
  engine                 = "postgres"
  engine_version         = "13.4"  # Update with your desired PostgreSQL version
  instance_class         = var.db_instance_class
  name                   = var.db_name
  username               = var.db_username
  password               = var.db_password
  db_subnet_group_name   = var.db_subnet_group_name
  vpc_security_group_ids = var.vpc_security_group_ids
}

