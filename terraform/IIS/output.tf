output "instance_id" {
  description = "ID of the IIS EC2 instance"
  value       = aws_instance.iis_server.id
}

output "public_ip" {
  description = "Elastic IP address of the IIS server"
  value       = aws_eip.iis_server_eip.public_ip
}

output "instance_private_ip" {
  description = "Private IP address of the IIS server"
  value       = aws_instance.iis_server.private_ip
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

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.iis_server_sg.id
}

output "telemetry_targets" {
  description = "Where telemetry data is being exported"
  value = {
    traces  = "AWS X-Ray"
    metrics = "AWS CloudWatch (EMF)"
    logs    = "AWS CloudWatch Logs"
  }
}
