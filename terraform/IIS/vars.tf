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

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
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
