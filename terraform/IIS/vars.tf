variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "webapp"
}

variable "product_name" {
  description = "Product name for tagging"
  type        = string
  default     = "WebApplication"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

variable "availability_zone" {
  description = "AWS Availability Zone for EC2 instance"
  type        = string
  default     = ""  # Empty means AWS will choose
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the IIS server"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "key_name" {
  description = "EC2 key pair name for RDP access"
  type        = string
  default     = ""
}

variable "otel_endpoint" {
  description = "OTEL collector endpoint (leave empty for local collector)"
  type        = string
  default     = ""
}

variable "otel_service_name" {
  description = "Service name for OTEL telemetry"
  type        = string
  default     = "iis-webserver"
}

variable "s3_bucket_name" {
  description = "S3 bucket name for application data"
  type        = string
  default     = ""  # Will be auto-generated if empty
}

variable "enable_load_balancer" {
  description = "Enable Application Load Balancer"
  type        = bool
  default     = false
}

variable "load_balancer_arn" {
  description = "Existing Load Balancer ARN to attach to (optional)"
  type        = string
  default     = ""
}

variable "target_group_port" {
  description = "Port for the target group"
  type        = number
  default     = 80
}

variable "health_check_path" {
  description = "Health check path for target group"
  type        = string
  default     = "/"
}

variable "enable_route53" {
  description = "Enable Route53 DNS record"
  type        = bool
  default     = false
}

variable "route53_zone_id" {
  description = "Route53 Hosted Zone ID"
  type        = string
  default     = ""
}

variable "route53_domain_name" {
  description = "Domain name for Route53 record"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for deployment (optional, uses default if empty)"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs for deployment (optional, uses default if empty)"
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "Specific AMI ID to use (optional, uses latest Windows Server if empty)"
  type        = string
  default     = ""
}
