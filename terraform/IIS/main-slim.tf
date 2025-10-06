terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

# 👇 Use the AWS CLI profile "sherpa" with the right permissions
provider "aws" {
  profile = "sherpa"
  region  = var.aws_region

  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Application = "IIS-WebServer"
    }
  }
}

# 🔗 Bring in prerequisites module
module "prerequisites" {
  source = "../prerequisites"

  region           = var.aws_region
  vpc_mapping      = var.vpc_mapping
  sg_mapping       = var.sg_mapping
  kms_mapping      = var.kms_mapping
  elb_mapping      = var.elb_mapping
  route53_mapping  = var.route53_mapping
  region_mapping   = var.region_mapping
  secret_names     = var.secret_names
}

# IAM Role for EC2 Instance (optional if you still want custom policies)
resource "aws_iam_role" "iis_server_role" {
  name = "${var.project_name}-iis-server-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })

  tags = {
    Name = "${var.project_name}-iis-server-role-${var.environment}"
  }
}

# Attach AWS managed policies (optional if not already in ssm-ec2-role)
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.iis_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.iis_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom IAM policy for OTEL (optional if not already in ssm-ec2-role)
resource "aws_iam_role_policy" "otel_telemetry_policy" {
  name = "${var.project_name}-iis-otel-policy-${var.environment}"
  role = aws_iam_role.iis_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket", "s3:PutObject"]
        Resource = ["arn:aws:s3:::*"]
      },
      {
        Effect   = "Allow"
        Action   = ["xray:PutTraceSegments", "xray:PutTelemetryRecords"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents", "logs:DescribeLogStreams"]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect   = "Allow"
        Action   = ["cloudwatch:PutMetricData"]
        Resource = ["*"]
      }
    ]
  })
}

# Security Group for IIS Server
resource "aws_security_group" "iis_server_sg" {
  name        = "${var.project_name}-iis-server-sg-${var.environment}"
  description = "Security group for IIS web server with OTEL"
  vpc_id      = module.prerequisites.vpc_id

  ingress { from_port = 80   to_port = 80   protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }
  ingress { from_port = 443  to_port = 443  protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }
  ingress { from_port = 3389 to_port = 3389 protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }
  ingress { from_port = 4317 to_port = 4317 protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }
  ingress { from_port = 4318 to_port = 4318 protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }
  ingress { from_port = 8888 to_port = 8888 protocol = "tcp" cidr_blocks = var.allowed_cidr_blocks }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instance with IIS and OTEL
resource "aws_instance" "iis_server" {
  ami                    = data.aws_ami.windows_server.id
  instance_type          = var.instance_type
  subnet_id              = element(module.prerequisites.subnet_ids, 0)
  vpc_security_group_ids = [aws_security_group.iis_server_sg.id]

  # 👇 Use the pre‑created instance profile instead of creating one here
  iam_instance_profile   = "arn:aws:iam::844302480461:instance-profile/ssm-ec2-role"

  key_name               = module.prerequisites.default_key_pair

  # ... keep your user_data, metadata_options, and tags as before
}

# Elastic IP
resource "aws_eip" "iis_server_eip" {
  instance = aws_instance.iis_server.id
  domain   = "vpc"
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "otel_logs" {
  name              = "/aws/otel/${var.project_name}-${var.environment}"
  retention_in_days = 7
}

