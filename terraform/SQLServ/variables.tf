# variables.tf - All configurable parameters for MSSQL deployment

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "mssql-secure"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

# VPC Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b", "us-west-2c"]
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
}

# RDS Configuration
variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.r5.xlarge"
}

variable "db_engine_version" {
  description = "SQL Server engine version"
  type        = string
  default     = "15.00.4236.7.v1"
}

variable "db_license_model" {
  description = "License model for SQL Server"
  type        = string
  default     = "license-included"
}

variable "db_edition" {
  description = "SQL Server edition"
  type        = string
  default     = "sqlserver-ee"
}

variable "db_allocated_storage" {
  description = "Allocated storage in GB"
  type        = number
  default     = 1000
}

variable "db_max_allocated_storage" {
  description = "Maximum allocated storage in GB for autoscaling"
  type        = number
  default     = 5000
}

variable "db_storage_type" {
  description = "Storage type"
  type        = string
  default     = "gp3"
}

variable "db_storage_iops" {
  description = "Storage IOPS"
  type        = number
  default     = 3000
}

variable "db_storage_throughput" {
  description = "Storage throughput"
  type        = number
  default     = 125
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "maindb"
}

variable "db_username" {
  description = "Database master username"
  type        = string
  default     = "sqlAdmin"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 1433
}

variable "db_multi_az" {
  description = "Enable Multi-AZ deployment"
  type        = bool
  default     = true
}

variable "db_publicly_accessible" {
  description = "Make database publicly accessible"
  type        = bool
  default     = false
}

variable "db_backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 30
}

variable "db_backup_window" {
  description = "Backup window"
  type        = string
  default     = "03:00-04:00"
}

variable "db_maintenance_window" {
  description = "Maintenance window"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

variable "db_delete_automated_backups" {
  description = "Delete automated backups when DB is deleted"
  type        = bool
  default     = false
}

variable "db_deletion_protection" {
  description = "Enable deletion protection"
  type        = bool
  default     = true
}

variable "db_copy_tags_to_snapshot" {
  description = "Copy tags to snapshots"
  type        = bool
  default     = true
}

variable "db_skip_final_snapshot" {
  description = "Skip final snapshot when deleting"
  type        = bool
  default     = false
}

variable "db_storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "db_performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "db_performance_insights_retention_period" {
  description = "Performance Insights retention period"
  type        = number
  default     = 731
}

variable "db_monitoring_interval" {
  description = "Enhanced monitoring interval"
  type        = number
  default     = 60
}

variable "db_auto_minor_version_upgrade" {
  description = "Enable auto minor version upgrade"
  type        = bool
  default     = false
}

variable "db_apply_immediately" {
  description = "Apply changes immediately"
  type        = bool
  default     = false
}

variable "db_ca_cert_identifier" {
  description = "CA certificate identifier"
  type        = string
  default     = "rds-ca-rsa2048-g1"
}

# Security Configuration
variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access the database"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "Security group IDs allowed to access the database"
  type        = list(string)
  default     = []
}

variable "kms_key_deletion_window" {
  description = "KMS key deletion window in days"
  type        = number
  default     = 30
}

variable "enable_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch"
  type        = list(string)
  default     = ["agent", "error"]
}

# SQL Server Specific Configuration
variable "sql_server_timezone" {
  description = "SQL Server timezone"
  type        = string
  default     = "UTC"
}

variable "sql_server_collation" {
  description = "SQL Server collation"
  type        = string
  default     = "SQL_Latin1_General_CP1_CI_AS"
}

variable "sql_server_backup_compression" {
  description = "Enable backup compression"
  type        = bool
  default     = true
}

variable "sql_server_clr_enabled" {
  description = "Enable CLR integration"
  type        = bool
  default     = false
}

variable "sql_server_cross_db_ownership_chaining" {
  description = "Enable cross-database ownership chaining"
  type        = bool
  default     = false
}

variable "sql_server_database_mail" {
  description = "Enable Database Mail"
  type        = bool
  default     = true
}

variable "sql_server_service_broker" {
  description = "Enable Service Broker"
  type        = bool
  default     = true
}

variable "sql_server_sql_server_agent" {
  description = "Enable SQL Server Agent"
  type        = bool
  default     = true
}

variable "sql_server_trustworthy" {
  description = "Enable trustworthy database property"
  type        = bool
  default     = false
}

# OpenTelemetry Configuration
variable "enable_otel" {
  description = "Enable OpenTelemetry integration"
  type        = bool
  default     = true
}

variable "otel_endpoint" {
  description = "OpenTelemetry endpoint"
  type        = string
  default     = ""
}

variable "enable_xray_tracing" {
  description = "Enable AWS X-Ray tracing"
  type        = bool
  default     = true
}

variable "custom_metrics_namespace" {
  description = "Custom CloudWatch metrics namespace"
  type        = string
  default     = "MSSQL/Custom"
}

# Tagging
variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project     = "mssql-secure"
    Environment = "prod"
    Terraform   = "true"
  }
}

# Alerting Configuration
variable "enable_cloudwatch_alarms" {
  description = "Enable CloudWatch alarms"
  type        = bool
  default     = true
}

variable "alarm_cpu_threshold" {
  description = "CPU alarm threshold percentage"
  type        = number
  default     = 80
}

variable "alarm_memory_threshold" {
  description = "Memory alarm threshold percentage"
  type        = number
  default     = 80
}

variable "alarm_disk_queue_depth_threshold" {
  description = "Disk queue depth alarm threshold"
  type        = number
  default     = 64
}

variable "alarm_free_storage_space_threshold" {
  description = "Free storage space alarm threshold in bytes"
  type        = number
  default     = 10737418240 # 10GB
}

variable "sns_topic_arn" {
  description = "SNS topic ARN for alarms"
  type        = string
  default     = ""
}

# Network Security
variable "enable_vpc_flow_logs" {
  description = "Enable VPC flow logs"
  type        = bool
  default     = true
}

variable "flow_log_destination_type" {
  description = "Flow log destination type (cloud-watch-logs or s3)"
  type        = string
  default     = "cloud-watch-logs"
}

# Backup Configuration
variable "enable_automated_backups" {
  description = "Enable automated backups"
  type        = bool
  default     = true
}

variable "enable_point_in_time_recovery" {
  description = "Enable point-in-time recovery"
  type        = bool
  default     = true
}

variable "backup_s3_bucket_name" {
  description = "S3 bucket name for manual backups"
  type        = string
  default     = ""
}

# Security Scanning
variable "enable_security_scanning" {
  description = "Enable security scanning"
  type        = bool
  default     = true
}

variable "enable_config_rules" {
  description = "Enable AWS Config rules"
  type        = bool
  default     = true
}
