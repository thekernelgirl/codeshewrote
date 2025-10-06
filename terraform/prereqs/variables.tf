variable "region" {
  description = "AWS region to operate in (us-east-1 or us-west-2)."
  type        = string
}

variable "vpc_mapping" {
  description = "Map of region to VPC ID."
  type        = map(string)
}

variable "sg_mapping" {
  description = "Map of region to SG IDs."
  type        = map(map(string))
}

variable "kms_mapping" {
  description = "Map of region to KMS Key IDs."
  type        = map(map(string))
}

variable "elb_mapping" {
  description = "Map of region to ELB details (name/arn/zone)."
  type        = map(map(object({
    name = string
  })))
}

variable "route53_mapping" {
  description = "Map of region to Route53 zones (public/private)."
  type        = map(map(object({
    name    = string
    private = bool
  })))
}

variable "region_mapping" {
  description = "Map of region to S3 bucket names for admin scripts and DB backups."
  type        = map(object({
    admin_scripts_bucket = string
    db_backup_bucket     = string
  }))
}

variable "secret_names" {
  description = "List of secret names to fetch from Secrets Manager."
  type        = list(string)
  default     = ["AdminPassword", "SherpaAdmin", "SherpaSSLkeypass", "DBZipPass"]
}

