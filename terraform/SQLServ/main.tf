# main.tf - Main infrastructure resources for secure MSSQL deployment

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

provider "aws" {
  region = var.region
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# Random password generation
resource "random_password" "db_password" {
  length  = 32
  special = true
}

# KMS Key for RDS encryption
resource "aws_kms_key" "rds" {
  description             = "KMS key for RDS encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-kms"
  })
}

resource "aws_kms_alias" "rds" {
  name          = "alias/${var.project_name}-${var.environment}-rds"
  target_key_id = aws_kms_key.rds.key_id
}

# KMS Key for CloudWatch Logs
resource "aws_kms_key" "cloudwatch" {
  description             = "KMS key for CloudWatch Logs encryption"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow CloudWatch Logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnEquals = {
            "kms:EncryptionContext:aws:logs:arn" = "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-cloudwatch-kms"
  })
}

resource "aws_kms_alias" "cloudwatch" {
  name          = "alias/${var.project_name}-${var.environment}-cloudwatch"
  target_key_id = aws_kms_key.cloudwatch.key_id
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-igw"
  })
}

# Public Subnets
resource "aws_subnet" "public" {
  count             = length(var.public_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-subnet-${count.index + 1}"
    Type = "Public"
  })
}

# Private Subnets
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-subnet-${count.index + 1}"
    Type = "Private"
  })
}

# Database Subnets (Isolated)
resource "aws_subnet" "database" {
  count             = length(var.database_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-database-subnet-${count.index + 1}"
    Type = "Database"
  })
}

# NAT Gateways
resource "aws_eip" "nat" {
  count  = length(var.public_subnet_cidrs)
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

resource "aws_nat_gateway" "main" {
  count         = length(var.public_subnet_cidrs)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-nat-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = length(var.private_subnet_cidrs)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main[count.index].id
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-database-rt"
  })
}

# Route Table Associations
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

resource "aws_route_table_association" "database" {
  count          = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

# VPC Flow Logs
resource "aws_cloudwatch_log_group" "vpc_flow_logs" {
  count             = var.enable_vpc_flow_logs ? 1 : 0
  name              = "/aws/vpc/flowlogs/${var.project_name}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flowlogs"
  })
}

resource "aws_iam_role" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flowlogs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "vpc-flow-logs.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "vpc_flow_logs" {
  count = var.enable_vpc_flow_logs ? 1 : 0
  name  = "${var.project_name}-${var.environment}-vpc-flowlogs-policy"
  role  = aws_iam_role.vpc_flow_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups",
          "logs:DescribeLogStreams"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_flow_log" "vpc" {
  count           = var.enable_vpc_flow_logs ? 1 : 0
  iam_role_arn    = aws_iam_role.vpc_flow_logs[0].arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_logs[0].arn
  traffic_type    = "ALL"
  vpc_id          = aws_vpc.main.id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-vpc-flowlog"
  })
}

# Security Groups
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for RDS MSSQL instance"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules for RDS
resource "aws_security_group_rule" "rds_ingress_private" {
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.application.id
  security_group_id        = aws_security_group.rds.id
  description              = "Allow access from application layer"
}

resource "aws_security_group_rule" "rds_ingress_cidr" {
  count             = length(var.allowed_cidr_blocks) > 0 ? 1 : 0
  type              = "ingress"
  from_port         = var.db_port
  to_port           = var.db_port
  protocol          = "tcp"
  cidr_blocks       = var.allowed_cidr_blocks
  security_group_id = aws_security_group.rds.id
  description       = "Allow access from allowed CIDR blocks"
}

resource "aws_security_group_rule" "rds_ingress_sg" {
  count                    = length(var.allowed_security_group_ids)
  type                     = "ingress"
  from_port                = var.db_port
  to_port                  = var.db_port
  protocol                 = "tcp"
  source_security_group_id = var.allowed_security_group_ids[count.index]
  security_group_id        = aws_security_group.rds.id
  description              = "Allow access from allowed security groups"
}

resource "aws_security_group_rule" "rds_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rds.id
  description       = "Allow all outbound traffic"
}

# Application Security Group (for reference)
resource "aws_security_group" "application" {
  name_prefix = "${var.project_name}-${var.environment}-app-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for application layer"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-app-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Subnet Group
resource "aws_db_subnet_group" "main" {
  name       = "${var.project_name}-${var.environment}-subnet-group"
  subnet_ids = aws_subnet.database[*].id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-subnet-group"
  })
}

# RDS Parameter Group
resource "aws_db_parameter_group" "mssql" {
  family = "sqlserver-ee-15.0"
  name   = "${var.project_name}-${var.environment}-mssql-params"

  # SQL Server Configuration Parameters
  parameter {
    name  = "backup compression default"
    value = var.sql_server_backup_compression ? "1" : "0"
  }

  parameter {
    name  = "clr enabled"
    value = var.sql_server_clr_enabled ? "1" : "0"
  }

  parameter {
    name  = "cross db ownership chaining"
    value = var.sql_server_cross_db_ownership_chaining ? "1" : "0"
  }

  parameter {
    name  = "Database Mail XPs"
    value = var.sql_server_database_mail ? "1" : "0"
  }

  parameter {
    name  = "Service Broker endpoint"
    value = var.sql_server_service_broker ? "1" : "0"
  }

  parameter {
    name  = "SQL Server Agent XPs"
    value = var.sql_server_sql_server_agent ? "1" : "0"
  }

  # Performance and Security Parameters
  parameter {
    name  = "max degree of parallelism"
    value = "0"
  }

  parameter {
    name  = "cost threshold for parallelism"
    value = "5"
  }

  parameter {
    name  = "max server memory (MB)"
    value = "0"
  }

  parameter {
    name  = "optimize for ad hoc workloads"
    value = "1"
  }

  parameter {
    name  = "remote access"
    value = "0"
  }

  parameter {
    name  = "remote admin connections"
    value = "1"
  }

  parameter {
    name  = "show advanced options"
    value = "1"
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mssql-params"
  })
}

# RDS Option Group
resource "aws_db_option_group" "mssql" {
  name                 = "${var.project_name}-${var.environment}-mssql-options"
  option_group_description = "Option group for SQL Server Enterprise Edition"
  engine_name          = "sqlserver-ee"
  major_engine_version = "15.00"

  # SQL Server Analysis Services
  option {
    option_name = "SSAS"
  }

  # SQL Server Integration Services
  option {
    option_name = "SSIS"
  }

  # SQL Server Reporting Services
  option {
    option_name = "SSRS"
  }

  # Transparent Data Encryption
  option {
    option_name = "TDE"
  }

  # SQL Server Audit
  option {
    option_name = "SQLSERVER_AUDIT"
    option_settings {
      name  = "S3_BUCKET_ARN"
      value = aws_s3_bucket.audit_logs.arn
    }
  }

  # Native Backup and Restore
  option {
    option_name = "SQLSERVER_BACKUP_RESTORE"
    option_settings {
      name  = "IAM_ROLE_ARN"
      value = aws_iam_role.rds_backup.arn
    }
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mssql-options"
  })
}

# S3 Bucket for SQL Server Audit Logs
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.project_name}-${var.environment}-mssql-audit-logs-${random_password.db_password.result}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-audit-logs"
  })
}

resource "aws_s3_bucket_encryption" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM Role for RDS Backup/Restore
resource "aws_iam_role" "rds_backup" {
  name = "${var.project_name}-${var.environment}-rds-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "rds_backup" {
  name = "${var.project_name}-${var.environment}-rds-backup-policy"
  role = aws_iam_role.rds_backup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.audit_logs.arn,
          "${aws_s3_bucket.audit_logs.arn}/*"
        ]
      }
    ]
  })
}

# Enhanced Monitoring IAM Role
resource "aws_iam_role" "rds_enhanced_monitoring" {
  name = "${var.project_name}-${var.environment}-rds-monitoring-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "rds_enhanced_monitoring" {
  role       = aws_iam_role.rds_enhanced_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

# RDS Instance
resource "aws_db_instance" "mssql" {
  identifier = "${var.project_name}-${var.environment}-mssql"

  # Engine Configuration
  engine              = var.db_edition
  engine_version      = var.db_engine_version
  license_model       = var.db_license_model
  instance_class      = var.db_instance_class
  
  # Database Configuration
  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result
  port     = var.db_port

  # Storage Configuration
  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage
  storage_type          = var.db_storage_type
  iops                  = var.db_storage_iops
  storage_throughput    = var.db_storage_throughput
  storage_encrypted     = var.db_storage_encrypted
  kms_key_id           = aws_kms_key.rds.arn

  # Network Configuration
  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  publicly_accessible    = var.db_publicly_accessible
  multi_az               = var.db_multi_az

  # Parameter and Option Groups
  parameter_group_name = aws_db_parameter_group.mssql.name
  option_group_name    = aws_db_option_group.mssql.name

  # Backup Configuration
  backup_retention_period = var.db_backup_retention_period
  backup_window          = var.db_backup_window
  copy_tags_to_snapshot  = var.db_copy_tags_to_snapshot
  delete_automated_backups = var.db_delete_automated_backups
  skip_final_snapshot    = var.db_skip_final_snapshot
  final_snapshot_identifier = var.db_skip_final_snapshot ? null : "${var.project_name}-${var.environment}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Maintenance Configuration
  maintenance_window         = var.db_maintenance_window
  auto_minor_version_upgrade = var.db_auto_minor_version_upgrade
  apply_immediately         = var.db_apply_immediately
  ca_cert_identifier        = var.db_ca_cert_identifier

  # Monitoring Configuration
  monitoring_interval = var.db_monitoring_interval
  monitoring_role_arn = aws_iam_role.rds_enhanced_monitoring.arn
  
  performance_insights_enabled = var.db_performance_insights_enabled
  performance_insights_retention_period = var.db_performance_insights_retention_period
  performance_insights_kms_key_id = aws_kms_key.rds.arn

  enabled_cloudwatch_logs_exports = var.enable_cloudwatch_logs_exports

  # Security Configuration
  deletion_protection = var.db_deletion_protection

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mssql"
  })

  depends_on = [
    aws_cloudwatch_log_group.rds_logs,
    aws_iam_role_policy_attachment.rds_enhanced_monitoring
  ]
}

# CloudWatch Log Groups for RDS
resource "aws_cloudwatch_log_group" "rds_logs" {
  for_each          = toset(var.enable_cloudwatch_logs_exports)
  name              = "/aws/rds/instance/${var.project_name}-${var.environment}-mssql/${each.key}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-rds-${each.key}-logs"
  })
}

# CloudWatch Alarms
resource "aws_cloudwatch_metric_alarm" "cpu_utilization" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-mssql-cpu-utilization"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  alarm_description   = "This metric monitors RDS CPU utilization"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mssql.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "database_connections" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-mssql-database-connections"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "DatabaseConnections"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors RDS database connections"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mssql.id
  }

  tags = var.tags
}

resource "aws_cloudwatch_metric_alarm" "free_storage_space" {
  count               = var.enable_cloudwatch_alarms ? 1 : 0
  alarm_name          = "${var.project_name}-${var.environment}-mssql-free-storage-space"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "FreeStorageSpace"
  namespace           = "AWS/RDS"
  period              = "120"
  statistic           = "Average"
  threshold           = var.alarm_free_storage_space_threshold
  alarm_description   = "This metric monitors RDS free storage space"
  alarm_actions       = var.sns_topic_arn != "" ? [var.sns_topic_arn] : []

  dimensions = {
    DBInstanceIdentifier = aws_db_instance.mssql.id
  }

  tags = var.tags
}

# X-Ray Tracing (when enabled)
resource "aws_xray_sampling_rule" "mssql" {
  count           = var.enable_xray_tracing ? 1 : 0
  rule_name       = "${var.project_name}-${var.environment}-mssql-sampling"
  priority        = 9000
  version         = 1
  reservoir_size  = 1
  fixed_rate      = 0.1
  url_path        = "*"
  host            = "*"
  http_method     = "*"
  service_type    = "*"
  service_name    = "${var.project_name}-${var.environment}-mssql"
  resource_arn    = "*"

  tags = var.tags
}

# Custom CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "mssql" {
  dashboard_name = "${var.project_name}-${var.environment}-mssql-dashboard"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          metrics = [
            ["AWS/RDS", "CPUUtilization", "DBInstanceIdentifier", aws_db_instance.mssql.id],
            [".", "DatabaseConnections", ".", "."],
            [".", "FreeStorageSpace", ".", "."],
            [".", "ReadLatency", ".", "."],
            [".", "WriteLatency", ".", "."]
          ]
          period = 300
          stat   = "Average"
          region = var.region
          title  = "RDS Metrics"
        }
      }
    ]
  })

  tags = var.tags
}

# AWS Secrets Manager for Database Password
resource "aws_secretsmanager_secret" "db_password" {
  name        = "${var.project_name}-${var.environment}-mssql-password"
  description = "Database password for MSSQL instance"
  kms_key_id  = aws_kms_key.rds.key_id

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-mssql-password"
  })
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id = aws_secretsmanager_secret.db_password.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    engine   = "sqlserver"
    host     = aws_db_instance.mssql.endpoint
    port     = var.db_port
    dbname   = var.db_name
  })
}

# OpenTelemetry Configuration
resource "aws_cloudwatch_log_group" "otel" {
  count             = var.enable_otel ? 1 : 0
  name              = "/aws/otel/${var.project_name}-${var.environment}"
  retention_in_days = 30
  kms_key_id        = aws_kms_key.cloudwatch.arn

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-otel-logs"
  })
}

# AWS Config Rules for Security Compliance
resource "aws_config_configuration_recorder" "main" {
  count    = var.enable_config_rules ? 1 : 0
  name     = "${var.project_name}-${var.environment}-config-recorder"
  role_arn = aws_iam_role.config[0].arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "main" {
  count           = var.enable_config_rules ? 1 : 0
  name            = "${var.project_name}-${var.environment}-config-delivery-channel"
  s3_bucket_name  = aws_s3_bucket.config[0].bucket
}

resource "aws_s3_bucket" "config" {
  count  = var.enable_config_rules ? 1 : 0
  bucket = "${var.project_name}-${var.environment}-config-${random_password.db_password.result}"

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-config"
  })
}

resource "aws_iam_role" "config" {
  count = var.enable_config_rules ? 1 : 0
  name  = "${var.project_name}-${var.environment}-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "config" {
  count      = var.enable_config_rules ? 1 : 0
  role       = aws_iam_role.config[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/ConfigRole"
}

# Config Rules
resource "aws_config_config_rule" "rds_encrypted" {
  count = var.enable_config_rules ? 1 : 0
  name  = "${var.project_name}-${var.environment}-rds-storage-encrypted"

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }

  depends_on = [aws_config_configuration_recorder.main]

  tags = var.tags
}
