output "instance_id" {
  description = "ID of the IIS EC2 instance"
  value       = aws_instance.iis_server.id
}

output "ami_id" {
  description = "AMI ID used for the instance"
  value       = aws_instance.iis_server.ami
}

output "vpc_id" {
  description = "VPC ID where resources are deployed"
  value       = local.vpc_id
}

output "subnet_id" {
  description = "Subnet ID where instance is deployed"
  value       = aws_instance.iis_server.subnet_id
}

output "availability_zone" {
  description = "Availability Zone of the instance"
  value       = aws_instance.iis_server.availability_zone
}

output "region" {
  description = "AWS Region"
  value       = var.aws_region
}

output "public_ip" {
  description = "Elastic IP address of the IIS server"
  value       = aws_eip.iis_server_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the IIS server"
  value       = aws_instance.iis_server.private_ip
}

output "instance_type" {
  description = "Instance type of the EC2 instance"
  value       = aws_instance.iis_server.instance_type
}

output "key_pair_name" {
  description = "Key pair name used for the instance"
  value       = aws_instance.iis_server.key_name
}

output "ebs_volume_info" {
  description = "EBS volume information"
  value = {
    volume_size = aws_instance.iis_server.root_block_device[0].volume_size
    volume_type = aws_instance.iis_server.root_block_device[0].volume_type
    encrypted   = aws_instance.iis_server.root_block_device[0].encrypted
  }
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket for application data"
  value       = aws_s3_bucket.app_data.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.app_data.arn
}

output "s3_bucket_region" {
  description = "Region of the S3 bucket"
  value       = aws_s3_bucket.app_data.region
}

output "http_url" {
  description = "HTTP URL to access the IIS server"
  value       = "http://${aws_eip.iis_server_eip.public_ip}"
}

output "otel_metrics_url" {
  description = "OTEL Collector metrics endpoint"
  value       = "http://${aws_eip.iis_server_eip.public_ip}:8888/metrics"
}

output "otel_health_url" {
  description = "OTEL Collector health check endpoint"
  value       = "http://${aws_eip.iis_server_eip.public_ip}:13133"
}

output "otel_grpc_endpoint" {
  description = "OTEL gRPC endpoint for external telemetry"
  value       = "${aws_eip.iis_server_eip.public_ip}:4317"
}

output "otel_http_endpoint" {
  description = "OTEL HTTP endpoint for external telemetry"
  value       = "${aws_eip.iis_server_eip.public_ip}:4318"
}

output "rdp_connection" {
  description = "RDP connection string"
  value       = "mstsc /v:${aws_eip.iis_server_eip.public_ip}"
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for OTEL telemetry"
  value       = aws_cloudwatch_log_group.otel_logs.name
}

output "iam_role_arn" {
  description = "ARN of the IAM role attached to the instance"
  value       = aws_iam_role.iis_server_role.arn
}

output "iam_role_name" {
  description = "Name of the IAM role"
  value       = aws_iam_role.iis_server_role.name
}

output "instance_profile_name" {
  description = "Name of the instance profile"
  value       = aws_iam_instance_profile.iis_server_profile.name
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.iis_server_sg.id
}

output "security_group_name" {
  description = "Name of the security group"
  value       = aws_security_group.iis_server_sg.name
}

output "load_balancer_arn" {
  description = "ARN of the Application Load Balancer"
  value       = var.enable_load_balancer && var.load_balancer_arn == "" ? aws_lb.iis_alb[0].arn : var.load_balancer_arn
}

output "load_balancer_dns" {
  description = "DNS name of the Application Load Balancer"
  value       = var.enable_load_balancer && var.load_balancer_arn == "" ? aws_lb.iis_alb[0].dns_name : null
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.iis_tg[0].arn : null
}

output "target_group_name" {
  description = "Name of the target group"
  value       = var.enable_load_balancer ? aws_lb_target_group.iis_tg[0].name : null
}

output "listener_arn" {
  description = "ARN of the ALB listener"
  value       = var.enable_load_balancer && var.load_balancer_arn == "" ? aws_lb_listener.iis_listener[0].arn : null
}

output "listener_rule_arn" {
  description = "ARN of the ALB listener rule"
  value       = var.enable_load_balancer && var.load_balancer_arn == "" ? aws_lb_listener_rule.iis_rule[0].arn : null
}

output "route53_record_name" {
  description = "Route 53 record name"
  value       = var.enable_route53 && var.route53_zone_id != "" ? aws_route53_record.iis_dns[0].name : null
}

output "route53_record_fqdn" {
  description = "Route 53 record FQDN"
  value       = var.enable_route53 && var.route53_zone_id != "" ? aws_route53_record.iis_dns[0].fqdn : null
}

output "route53_alb_record_name" {
  description = "Route 53 ALB record name"
  value       = var.enable_route53 && var.enable_load_balancer && var.route53_zone_id != "" ? aws_route53_record.iis_alb_dns[0].name : null
}

output "route53_alb_record_fqdn" {
  description = "Route 53 ALB record FQDN"
  value       = var.enable_route53 && var.enable_load_balancer && var.route53_zone_id != "" ? aws_route53_record.iis_alb_dns[0].fqdn : null
}

output "ssm_agent_status" {
  description = "SSM Agent configuration status"
  value       = "SSM Agent installed and configured via IAM role: ${aws_iam_role.iis_server_role.name}"
}

output "tags" {
  description = "Tags applied to the instance"
  value       = aws_instance.iis_server.tags
}

output "telemetry_targets" {
  description = "Where telemetry data is being exported"
  value = {
    traces  = "AWS X-Ray"
    metrics = "AWS CloudWatch (EMF)"
    logs    = "AWS CloudWatch Logs"
  }
}

output "deployment_summary" {
  description = "Complete deployment summary"
  value = {
    instance = {
      id                = aws_instance.iis_server.id
      type              = aws_instance.iis_server.instance_type
      ami               = aws_instance.iis_server.ami
      availability_zone = aws_instance.iis_server.availability_zone
      public_ip         = aws_eip.iis_server_eip.public_ip
      private_ip        = aws_instance.iis_server.private_ip
    }
    networking = {
      vpc_id            = local.vpc_id
      subnet_id         = aws_instance.iis_server.subnet_id
      security_group_id = aws_security_group.iis_server_sg.id
      elastic_ip        = aws_eip.iis_server_eip.public_ip
    }
    storage = {
      s3_bucket = aws_s3_bucket.app_data.id
      ebs = {
        size      = aws_instance.iis_server.root_block_device[0].volume_size
        type      = aws_instance.iis_server.root_block_device[0].volume_type
        encrypted = aws_instance.iis_server.root_block_device[0].encrypted
      }
    }
    load_balancing = var.enable_load_balancer ? {
      alb_arn          = var.load_balancer_arn != "" ? var.load_balancer_arn : aws_lb.iis_alb[0].arn
      target_group_arn = aws_lb_target_group.iis_tg[0].arn
    } : null
    dns = var.enable_route53 ? {
      domain = var.route53_domain_name
      zone_id = var.route53_zone_id
    } : null
    monitoring = {
      cloudwatch_log_group = aws_cloudwatch_log_group.otel_logs.name
      otel_endpoints = {
        metrics = "http://${aws_eip.iis_server_eip.public_ip}:8888/metrics"
        health  = "http://${aws_eip.iis_server_eip.public_ip}:13133"
        grpc    = "${aws_eip.iis_server_eip.public_ip}:4317"
        http    = "${aws_eip.iis_server_eip.public_ip}:4318"
      }
    }
    tags = {
      Product     = var.product_name
      Application = var.project_name
      Environment = var.environment
    }
  }
}
