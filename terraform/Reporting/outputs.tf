output "instance_id" {
  description = "Reporting server instance ID."
  value       = aws_instance.rs_server.id
}

output "instance_private_ip" {

