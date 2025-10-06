terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

# VPC Lookup – because reinventing the wheel is boring
data "aws_vpc" "selected" {
  id = lookup(var.vpc_mapping, var.region, null)
}

# Subnets – grab them like hot wings at happy hour
data "aws_subnets" "selected" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

# Security Groups – the bouncers of your cloud nightclub
data "aws_security_group" "sgs" {
  for_each = lookup(var.sg_mapping, var.region, {})
  id       = each.value
}

# KMS Keys – because plaintext is for amateurs
data "aws_kms_key" "kms" {
  for_each = lookup(var.kms_mapping, var.region, {})
  key_id   = each.value
}

# ELBs – already cooked and served, we just plate them
data "aws_lb" "elbs" {
  for_each = lookup(var.elb_mapping, var.region, {})
  name     = each.value["name"]
}

# Route53 Zones – DNS, the phonebook of the internet
data "aws_route53_zone" "zones" {
  for_each = lookup(var.route53_mapping, var.region, {})
  name     = each.value["name"]
  private_zone = each.value["private"]
}

# S3 Buckets – the junk drawers of the cloud
data "aws_s3_bucket" "admin_scripts" {
  bucket = lookup(var.region_mapping[var.region], "admin_scripts_bucket", null)
}

data "aws_s3_bucket" "db_backups" {
  bucket = lookup(var.region_mapping[var.region], "db_backup_bucket", null)
}

# Secrets Manager – where the skeletons are buried
data "aws_secretsmanager_secret" "secrets" {
  for_each = toset(var.secret_names)
  name     = each.value
}

# Default EC2 Key Pair – tagged with Boto3-Default=True
data "aws_key_pair" "default" {
  filter {
    name   = "tag:Boto3-Default"
    values = ["True"]
  }
}

