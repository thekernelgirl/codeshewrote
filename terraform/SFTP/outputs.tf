output "instance_id" {
  description = "SFTP server instance ID."
  value       = aws_instance.sftp.id
}

output "instance_private_ip" {
  description = "Private IP of the SFTP server."
  value       = aws_network_interface.sftp_eni.private_ip
}

output "instance_public_ip" {
  description = "Public IP of the SFTP server."
  value       = aws_eip.sftp_eip.public_ip
}

output "bucket_name" {
  description = "S3 bucket backing the SFTP share."
  value       = aws_s3_bucket.sftp_bucket.bucket
}

output "storagegateway_share_id"
