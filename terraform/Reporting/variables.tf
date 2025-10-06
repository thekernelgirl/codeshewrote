variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "environment" {
  description = "Environment (e.g., dev, prod)."
  type        = string
}

variable "client_code" {
  description = "Client code used in hostnames."
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for the RS server."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs."
  type        = list(string)
}

variable "ec2_rs_type" {
  description = "EC2 instance type for RS server."
  type        = string
  default     = "t3.large"
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "IAM instance profile ARN."
  type        = string
  default     = "arn:aws:iam::844302480461:instance-profile/ssm-ec2-role"
}

variable "root_volume_size" {
  description = "Root volume size in GB."
  type        = number
  default     = 60
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for EBS encryption."
  type        = string
}

variable "route53_public_zone_id" {
  description = "Public Route53 zone ID."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name."
  type        = string
}

variable "alb_hosted_zone_id" {
  description = "ALB hosted zone ID."
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB listener ARN."
  type        = string
}

variable "alb_rule_priority" {
  description = "Listener rule priority."
  type        = number
  default     = 200
}

variable "enable_cloudflare" {
  description = "Enable Cloudflare DNS records."
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID."
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "VPC ID for target group."
  type        = string
}

variable "tags_common" {
  description = "Common tags to merge into resources."
  type        = map(string)
  default     = {}
}

