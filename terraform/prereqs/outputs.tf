output "vpc_id" {
  value       = data.aws_vpc.selected.id
  description = "The chosen VPC ID."
}

output "subnet_ids" {
  value       = data.aws_subnets.selected.ids
  description = "All subnet IDs in the selected VPC."
}

output "security_groups" {
  value       = { for k, sg in data.aws_security_group.sgs : k => sg.id }
  description = "Security group IDs per mapping."
}

output "kms_keys" {
  value       = { for k, kms in data.aws_kms_key.kms : k => kms.arn }
  description = "KMS Key ARNs per mapping."
}

output "elbs" {
  value       = { for k, elb in data.aws_lb.elbs : k => elb.arn }
  description = "ELB ARNs per mapping."
}

output "route53_zones" {
  value       = { for k, z in data.aws_route53_zone.zones : k => z.zone_id }
  description = "Route53 Zone IDs per mapping."
}

output "s3_buckets" {
  value = {
    admin_scripts = data.aws_s3_bucket.admin_scripts.id
    db_backups    = data.aws_s3_bucket.db_backups.id
  }
  description = "S3 bucket IDs for admin scripts and DB backups."
}

output "secrets" {
  value       = { for k, s in data.aws_secretsmanager_secret.secrets : k => s.arn }
  description = "Secrets Manager ARNs."
}

output "default_key_pair" {
  value       = data.aws_key_pair.default.key_name
  description = "Default EC2 key pair name tagged with Boto3-Default=True."
}

