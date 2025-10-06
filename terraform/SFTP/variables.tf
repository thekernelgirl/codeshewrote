variable "aws_region" {
  description = "AWS region to deploy into."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
}

variable "client_code" {
  description = "Client code used in hostnames."
  type        = string
}

variable "subnet_id_c" {
  description = "Subnet ID for subnet-c."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs for the ENI."
  type        = list(string)
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
  default     = "t4g.nano"
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
}

variable "root_volume_size" {
  description = "Root volume size in GB."
  type        = number
  default     = 8
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for EBS encryption."
  type        = string
}

variable "linux_timezone" {
  description = "Linux timezone (e.g., UTC, America/New_York)."
  type        = string
  default     = "UTC"
}

variable "sftp_user" {
  description = "SFTP username."
  type        = string
}

variable "sftp_password" {
  description = "SFTP user password."
  type        = string
  sensitive   = true
}

variable "route53_private_zone_id" {
  description = "Private Route53 zone ID."
  type        = string
}

variable "route53_public_zone_id" {
  description = "Public Route53 zone ID."
  type        = string
}

variable "enable_cloudflare" {
  description = "Enable Cloudflare DNS record."
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

variable "storage_gateway_arn" {
  description = "ARN of the Storage Gateway."
  type        = string
}

variable "storage_gateway_role_arn" {
  description = "IAM role ARN for Storage Gateway file share."
  type        = string
}

variable "sftp_client_list" {
  description = "List of client IPs allowed to mount the NFS share."
  type        = list(string)
}

