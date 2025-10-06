variable "aws_region" {
  description = "AWS region (e.g., us-east-1)."
  type        = string
}

variable "environment" {
  description = "Environment name (e.g., dev, prod)."
  type        = string
}

variable "client_code" {
  description = "Client code used in hostnames and paths (e.g., abc)."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for target group."
  type        = string
}

variable "subnet_id_a" {
  description = "Subnet ID for subnet-a where the BFM app server runs."
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs to attach to the ENI."
  type        = list(string)
}

variable "private_ip" {
  description = "Optional static private IP for the ENI."
  type        = string
  default     = ""
}

variable "ec2_bfm_type" {
  description = "EC2 instance type for BFM (e.g., r7i.large)."
  type        = string
}

variable "iam_instance_profile_arn" {
  description = "IAM instance profile ARN (e.g., ssm-ec2-role)."
  type        = string
  default     = "arn:aws:iam::844302480461:instance-profile/ssm-ec2-role"
}

variable "kms_key_id" {
  description = "KMS key ID or ARN for EBS encryption."
  type        = string
}

variable "ebs_mapping" {
  description = "EBS mapping object for BFM root/data."
  type = object({
    bfm = object({
      root_gb          = number  # e.g., 80
      data_gb          = number  # e.g., 60
      data_device_name = string  # e.g., /dev/sdf
    })
  })
}

variable "route53_private_zone_id" {
  description = "Private Route53 zone ID for bfm.cloud."
  type        = string
}

variable "route53_public_zone_id" {
  description = "Public Route53 zone ID for bfm.cloud."
  type        = string
}

variable "alb_dns_name" {
  description = "ALB DNS name used for apex alias (e.g., internal-...elb.amazonaws.com)."
  type        = string
}

variable "alb_hosted_zone_id" {
  description = "ALB hosted zone ID for Route53 alias."
  type        = string
}

variable "alb_listener_arn" {
  description = "ALB HTTPS listener ARN to attach the listener rule."
  type        = string
}

variable "alb_rule_priority" {
  description = "Listener rule priority."
  type        = number
  default     = 150
}

variable "windows_time_zone" {
  description = "Windows time zone ID (e.g., Eastern Standard Time)."
  type        = string
  default     = "Eastern Standard Time"
}

variable "gateway_share_host" {
  description = "Hostname or IP of the gateway fileshare server."
  type        = string
}

variable "gateway_share_path" {
  description = "Share path (e.g., apps$)."
  type        = string
}

variable "rdp_cert_filename" {
  description = "Filename of the RDP PFX cert on the gateway share."
  type        = string
}

variable "rdp_cert_password" {
  description = "Password for the RDP PFX certificate."
  type        = string
  sensitive   = true
}

variable "bfm_zip_filename" {
  description = "BFM package zip filename (e.g., bfmacd0.zip) on the gateway share."
  type        = string
  default     = "bfmacd0.zip"
}

variable "ssms_installer" {
  description = "SSMS installer filename on the gateway share."
  type        = string
  default     = "SSMS-Setup-ENU.exe"
}

variable "webroot_installer" {
  description = "Webroot agent installer filename on the gateway share."
  type        = string
  default     = "webroot.exe"
}

variable "enable_cloudflare" {
  description = "Enable Cloudflare record mirroring."
  type        = bool
  default     = false
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token (required if enable_cloudflare)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for bfm.cloud."
  type        = string
  default     = ""
}

variable "tags_common" {
  description = "Common tags to merge into resources."
  type        = map(string)
  default     = {}
}

