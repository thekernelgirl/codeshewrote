output "instance_id" {
  description = "DB server instance ID."
  value       = aws_instance.db_server.id
}

output "instance_private_ip" {
  description = "DB server private IP."
  value       = aws_network_interface.db_eni.private_ip
}

output "instance_public_ip" {
  description = "DB server public IP via EIP."
  value       = aws_eip.db_eip.public_ip
}

output "eni_id" {
  description = "Network interface ID."
  value       = aws_network_interface.db_eni.id
}

output "route53_private_a_fqdn" {
  description = "Private A record FQDN."
  value       = aws_route53_record.db_private_a.fqdn
}

output "route53_private_cname_fqdn" {
  description = "Private CNAME alias FQDN."
  value       = aws_route53_record.db_private_cname.fqdn
}

output "route53_public_a_fqdn" {
  description = "Public A record FQDN."
  value       = aws_route53_record.db_public_a.fqdn
}

output "route53_public_cname_fqdn" {
  description = "Public CNAME alias FQDN."
  value       = aws_route53_record.db_public_cname.fqdn
}

output "cloudflare_public_a_id" {
  description = "Cloudflare public A record ID (if enabled)."
  value       = try(cloudflare_record.cf_db_public_a[0].id, null)
}

output "cloudflare_public_cname_id" {
  description = "Cloudflare public CNAME record ID (if enabled)."
  value       = try(cloudflare_record.cf_db_public_cname[0].id, null)
}

output "db_bucket_name" {
  description = "S3 bucket used for lifecycle rules."
  value       = aws_s3_bucket.db_bucket.bucket
}

