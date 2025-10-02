# outputs.tf - Output values for MSSQL deployment

# VPC Outputs
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = aws_vpc.main.cidr_block
}

output "vpc_arn" {
  description = "ARN of the VPC"
  value       = aws_vpc.main.arn
}

# Subnet Outputs
output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

output "database_subnet_ids" {
  description = "IDs of the database subnets"
  value       = aws_subnet.database[*].id
}

output "database_subnet_group_name" {
  description = "Name of the database subnet group"
  value       = aws_db_subnet_group.main.name
}

# Security Group Outputs
output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "application_security_group_id" {
  description = "ID of the application security group"
  value       = aws_security_group.application.id
}

# RDS Instance Outputs
output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.mssql.id
}

output "rds_instance_identifier" {
  description = "RDS instance identifier"
  value       = aws_db_instance.mssql.identifier
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.mssql.arn
}

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.mssql.endpoint
}

output "rds_instance_hosted_zone_id" {
  description = "RDS instance hosted zone ID"
  value       = aws_db_instance.mssql.hosted_zone_id
}

output "rds_instance_port" {
  description = "RDS instance port"
  value       = aws_db_instance.mssql.port
}

output "rds_instance_status" {
  description = "RDS instance status"
  value       = aws_db_instance.mssql.status
}

output "rds_instance_engine" {
  description = "RDS instance engine"
  value       = aws_db_instance.mssql.engine
}

output "rds_instance_engine_version" {
  description = "RDS instance engine version"
  value       = aws_db_instance.mssql.engine_version
}

output "rds_instance_class" {
  description = "RDS instance class"
  value       = aws_db_instance.mssql.instance_class
}

output "rds_instance_storage" {
  description = "RDS instance allocated storage"
  value       = aws_db_instance.mssql.allocated_storage
}

output "rds_instance_storage_type" {
  description = "RDS instance storage type"
  value       = aws_db_instance.mssql.storage_type
}

output "rds_instance_storage_encrypted" {
  description = "Whether RDS instance storage is encrypted"
  value       = aws_db_instance.mssql.storage_encrypted
}

output "rds_instance_multi_az" {
  description = "Whether RDS instance is multi-AZ"
  value       = aws_db_instance.mssql.multi_az
}

output "rds_instance_backup_retention_period" {
  description = "RDS instance backup retention period"
  value       = aws_db_instance.mssql.backup_retention_period
}

output "rds_instance_backup_window" {
  description = "RDS instance backup window"
  value       = aws_db_instance.mssql.backup_window
}

output "rds_instance_maintenance_window" {
  description = "RDS instance maintenance window"
  value       = aws_db_instance.mssql.maintenance_window
}

# Database Connection Information
output "database_name" {
  description = "Database name"
  value       = aws_db_instance.mssql.db_name
}

output "database_username" {
  description = "Database master username"
  value       = aws_db_instance.mssql.username
  sensitive   = true
}

output "database_connection_string" {
  description = "Database connection string"
  value       = "Server=${aws_db_instance.mssql.endpoint},${aws_db_instance.mssql.port};Database=${aws_db_instance.mssql.db_name};User Id=${aws_db_instance.mssql.username};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
  sensitive   = true
}

# Parameter and Option Groups
output "rds_parameter_group_name" {
  description = "Name of the RDS parameter group"
  value       = aws_db_parameter_group.mssql.name
}

output "rds_parameter_group_arn" {
  description = "ARN of the RDS parameter group"
  value       = aws_db_parameter_group.mssql.arn
}

output "rds_option_group_name" {
  description = "Name of the RDS option group"
  value       = aws_db_option_group.mssql.name
}

output "rds_option_group_arn" {
  description = "ARN of the RDS option group"
  value       = aws_db_option_group.mssql.arn
}

# KMS Keys
output "rds_kms_key_id" {
  description = "KMS key ID for RDS encryption"
  value       = aws_kms_key.rds.key_id
}

output "rds_kms_key_arn" {
  description = "KMS key ARN for RDS encryption"
  value       = aws_kms_key.rds.arn
}

output "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch encryption"
  value       = aws_kms_key.cloudwatch.key_id
}

output "cloudwatch_kms_key_arn" {
  description = "KMS key ARN for CloudWatch encryption"
  value       = aws_kms_key.cloudwatch.arn
}

# Secrets Manager
output "db_password_secret_arn" {
  description = "ARN of the database password secret"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "db_password_secret_name" {
  description = "Name of the database password secret"
  value       = aws_secretsmanager_secret.db_password.name
}

# S3 Buckets
output "audit_logs_bucket_name" {
  description = "Name of the audit logs S3 bucket"
  value       = aws_s3_bucket.audit_logs.bucket
}

output "audit_logs_bucket_arn" {
  description = "ARN of the audit logs S3 bucket"
  value       = aws_s3_bucket.audit_logs.arn
}

output "config_bucket_name" {
  description = "Name of the AWS Config S3 bucket"
  value       = var.enable_config_rules ? aws_s3_bucket.config[0].bucket : null
}

output "config_bucket_arn" {
  description = "ARN of the AWS Config S3 bucket"
  value       = var.enable_config_rules ? aws_s3_bucket.config[0].arn : null
}

# IAM Roles
output "rds_enhanced_monitoring_role_arn" {
  description = "ARN of the RDS enhanced monitoring role"
  value       = aws_iam_role.rds_enhanced_monitoring.arn
}

output "rds_backup_role_arn" {
  description = "ARN of the RDS backup role"
  value       = aws_iam_role.rds_backup.arn
}

output "vpc_flow_logs_role_arn" {
  description = "ARN of the VPC flow logs role"
  value       = var.enable_vpc_flow_logs ? aws_iam_role.vpc_flow_logs[0].arn : null
}

output "config_role_arn" {
  description = "ARN of the AWS Config role"
  value       = var.enable_config_rules ? aws_iam_role.config[0].arn : null
}

# CloudWatch Log Groups
output "vpc_flow_logs_group_name" {
  description = "Name of the VPC flow logs CloudWatch log group"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].name : null
}

output "vpc_flow_logs_group_arn" {
  description = "ARN of the VPC flow logs CloudWatch log group"
  value       = var.enable_vpc_flow_logs ? aws_cloudwatch_log_group.vpc_flow_logs[0].arn : null
}

output "rds_log_groups" {
  description = "Map of RDS CloudWatch log groups"
  value = {
    for log_type in var.enable_cloudwatch_logs_exports :
    log_type => aws_cloudwatch_log_group.rds_logs[log_type].name
  }
}

output "otel_log_group_name" {
  description = "Name of the OpenTelemetry CloudWatch log group"
  value       = var.enable_otel ? aws_cloudwatch_log_group.otel[0].name : null
}

output "otel_log_group_arn" {
  description = "ARN of the OpenTelemetry CloudWatch log group"
  value       = var.enable_otel ? aws_cloudwatch_log_group.otel[0].arn : null
}

# CloudWatch Alarms
output "cloudwatch_alarm_cpu_utilization_arn" {
  description = "ARN of the CPU utilization CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.cpu_utilization[0].arn : null
}

output "cloudwatch_alarm_database_connections_arn" {
  description = "ARN of the database connections CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.database_connections[0].arn : null
}

output "cloudwatch_alarm_free_storage_space_arn" {
  description = "ARN of the free storage space CloudWatch alarm"
  value       = var.enable_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.free_storage_space[0].arn : null
}

# CloudWatch Dashboard
output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard"
  value       = "https://${var.region}.console.aws.amazon.com/cloudwatch/home?region=${var.region}#dashboards:name=${aws_cloudwatch_dashboard.mssql.dashboard_name}"
}

# X-Ray
output "xray_sampling_rule_arn" {
  description = "ARN of the X-Ray sampling rule"
  value       = var.enable_xray_tracing ? aws_xray_sampling_rule.mssql[0].arn : null
}

# Networking Details
output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.main.id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = aws_nat_gateway.main[*].id
}

output "elastic_ip_addresses" {
  description = "Elastic IP addresses for NAT Gateways"
  value       = aws_eip.nat[*].public_ip
}

# Route Tables
output "public_route_table_id" {
  description = "ID of the public route table"
  value       = aws_route_table.public.id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = aws_route_table.private[*].id
}

output "database_route_table_id" {
  description = "ID of the database route table"
  value       = aws_route_table.database.id
}

# Performance Insights
output "performance_insights_enabled" {
  description = "Whether Performance Insights is enabled"
  value       = aws_db_instance.mssql.performance_insights_enabled
}

output "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights encryption"
  value       = aws_db_instance.mssql.performance_insights_kms_key_id
}

# Enhanced Monitoring
output "enhanced_monitoring_enabled" {
  description = "Whether enhanced monitoring is enabled"
  value       = aws_db_instance.mssql.monitoring_interval > 0
}

output "enhanced_monitoring_interval" {
  description = "Enhanced monitoring interval in seconds"
  value       = aws_db_instance.mssql.monitoring_interval
}

# AWS Config
output "config_recorder_name" {
  description = "Name of the AWS Config recorder"
  value       = var.enable_config_rules ? aws_config_configuration_recorder.main[0].name : null
}

output "config_delivery_channel_name" {
  description = "Name of the AWS Config delivery channel"
  value       = var.enable_config_rules ? aws_config_delivery_channel.main[0].name : null
}

# Environment Information
output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "environment" {
  description = "Environment name"
  value       = var.environment
}

output "region" {
  description = "AWS region"
  value       = var.region
}

output "availability_zones" {
  description = "Availability zones used"
  value       = var.availability_zones
}

# Resource Tags
output "common_tags" {
  description = "Common tags applied to resources"
  value       = var.tags
}

# Connection Helper Outputs
output "jdbc_connection_string" {
  description = "JDBC connection string for SQL Server"
  value       = "jdbc:sqlserver://${aws_db_instance.mssql.endpoint}:${aws_db_instance.mssql.port};databaseName=${aws_db_instance.mssql.db_name};encrypt=true;trustServerCertificate=false;loginTimeout=30;"
  sensitive   = true
}

output "odbc_connection_string" {
  description = "ODBC connection string for SQL Server"
  value       = "Driver={ODBC Driver 17 for SQL Server};Server=${aws_db_instance.mssql.endpoint},${aws_db_instance.mssql.port};Database=${aws_db_instance.mssql.db_name};UID=${aws_db_instance.mssql.username};Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
  sensitive   = true
}

output "powershell_connection_example" {
  description = "PowerShell connection example"
  value       = <<-EOT
$connectionString = "Server=${aws_db_instance.mssql.endpoint},${aws_db_instance.mssql.port};Database=${aws_db_instance.mssql.db_name};User Id=${aws_db_instance.mssql.username};Encrypt=true;TrustServerCertificate=false;Connection Timeout=30;"
$connection = New-Object System.Data.SqlClient.SqlConnection($connectionString)
EOT
  sensitive   = true
}

# Summary Output
output "deployment_summary" {
  description = "Summary of the deployed infrastructure"
  value = {
    vpc_id                  = aws_vpc.main.id
    rds_endpoint           = aws_db_instance.mssql.endpoint
    rds_port              = aws_db_instance.mssql.port
    rds_instance_class    = aws_db_instance.mssql.instance_class
    rds_engine_version    = aws_db_instance.mssql.engine_version
    rds_multi_az          = aws_db_instance.mssql.multi_az
    rds_storage_encrypted = aws_db_instance.mssql.storage_encrypted
    rds_backup_retention  = aws_db_instance.mssql.backup_retention_period
    performance_insights  = aws_db_instance.mssql.performance_insights_enabled
    enhanced_monitoring   = aws_db_instance.mssql.monitoring_interval > 0
    subnet_isolation      = "Enabled (Database subnets isolated)"
    security_features     = "Full encryption, VPC Flow Logs, AWS Config, CloudWatch Monitoring"
    sql_server_features   = "All enterprise features enabled via option group"
    opentelemetry        = var.enable_otel ? "Enabled" : "Disabled"
    xray_tracing         = var.enable_xray_tracing ? "Enabled" : "Disabled"
  }
}
