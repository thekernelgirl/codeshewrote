variable "aws_region" {
  description = "AWS region."
  type        = string
}

variable "environment" {
  description = "Environment (e.g., e19, nw19, dev, prod)."
  type        = string
}

variable "client_code" {
  description = "Client code for long hostnames (e.g., e19, nw19)."
  type        = string
}

variable "client_short" {
  description = "Short client code for alias (e.g., e19 → e)."
  type        = string
}

variable "subnet_id_b" {
  description = "Subnet ID for subnet-b."
  type        = string
}

variable "security_group_ids" {
  description = "Security group IDs attached to the ENI."
  type        = list(string)
}

variable "private_ip" {
  description = "Optional static private IP."
  type        = string
  default     = ""
}

variable "db_instance_type" {
  description = "EC2 instance type for DB (e.g., r7i.large)."
  type        = string
  default     = "r7i.large"
}

variable "key_name" {
  description = "EC2 key pair name."
  type        = string
  default     = null
}

variable "iam_instance_profile_arn" {
  description = "IAM instance profile ARN (for S3/SES/SSM access)."
  type        = string
  default     = "arn:aws:iam::844302480461:instance-profile/ssm-ec2-role"
}

variable "kms_key_id" {
  description = "KMS key ID/ARN for EBS encryption."
  type        = string
}

variable "ebs_mapping" {
  description = "EBS mapping for DB server volumes."
  type = object({
    db = object({
      root_gb           = number     # e.g., 30
      data_gb           = number     # e.g., 250
      logs_gb           = number     # e.g., 225
      backup_gb         = number     # e.g., 200
      data_device_name  = string     # e.g., /dev/xvdb
      logs_device_name  = string     # e.g., /dev/xvdc
      backup_device_name= string     # e.g., /dev/xvdd
    })
  })
}

variable "linux_timezone" {
  description = "Linux timezone (e.g., UTC or America/New_York)."
  type        = string
  default     = "UTC"
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
  description = "Enable Cloudflare mirroring."
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
  description = "Cloudflare zone ID for bfm.cloud."
  type        = string
  default     = ""
}

variable "admin_scripts_bucket" {
  description = "S3 bucket name for admin scripts."
  type        = string
}

variable "admin_scripts_prefix" {
  description = "Prefix in admin bucket for cron/job scripts."
  type        = string
  default     = "db/jobs"
}

variable "admin_jobs_prefix" {
  description = "Prefix in admin bucket for SQL Agent job scripts (.sql)."
  type        = string
  default     = "db/agent_jobs"
}

variable "db_backup_bucket" {
  description = "S3 bucket with DB backups."
  type        = string
}

variable "bfm_backup_prefix" {
  description = "Prefix in backup bucket for BFM DB backups."
  type        = string
  default     = "bfm"
}

variable "obj_backup_prefix" {
  description = "Prefix in backup bucket for OBJ DB backups."
  type        = string
  default     = "obj"
}

variable "db_zip_password" {
  description = "Password for zipped DB backups."
  type        = string
  sensitive   = true
}

variable "sa_password" {
  description = "SQL Server 'sa' password used for bootstrap/restores."
  type        = string
  sensitive   = true
}

variable "sql_edition" {
  description = "SQL Server edition (Developer, Standard, Web, Enterprise)."
  type        = string
  default     = "Developer"
}

variable "sql_memory_max_mb" {
  description = "Max memory cap in MB for SQL Server."
  type        = number
  default     = 8192
}

variable "sql_logins" {
  description = "List of SQL logins to create."
  type = list(object({
    name     = string
    password = string
  }))
  default = []
}

variable "ses_smtp_host" {
  description = "SES SMTP host (e.g., email-smtp.us-east-1.amazonaws.com)."
  type        = string
  default     = ""
}

variable "ses_smtp_port" {
  description = "SES SMTP port (typically 587 or 465)."
  type        = number
  default     = 587
}

variable "ses_smtp_user" {
  description = "SES SMTP username."
  type        = string
  default     = ""
}

variable "ses_smtp_password" {
  description = "SES SMTP password."
  type        = string
  default     = ""
  sensitive   = true
}

variable "ses_from_email" {
  description = "Default 'from' email for DB Mail."
  type        = string
  default     = ""
}

variable "db_s3_bucket_name" {
  description = "S3 bucket for ongoing DB lifecycle prefixes."
  type        = string
}

variable "db_s3_prefix" {
  description = "Base prefix for lifecycle folders (weekly/monthly/yearly)."
  type        = string
  default     = "db"
}

variable "db_s3_bucket_force_destroy" {
  description = "Allow bucket deletion even if non-empty (for testing)."
  type        = bool
  default     = false
}

variable "tags_common" {
  description = "Common tags to merge into all resources."
  type        = map(string)
  default     = {}
}

