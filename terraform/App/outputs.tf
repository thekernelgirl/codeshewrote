output "instance_id" {
  description = "BFM application server instance ID."
  value       = aws_instance.bfm_app.id
}

output "instance_private_ip" {
  description = "Private IP of the BFM application server."
  value       = aws_network_interface.bfm_eni.private_ip
}

output "instance_public_ip" {
  description = "Public IP via EIP."
  value       = aws_eip.bfm_eip.public_ip
}

output "eni_id" {
  description = "Network interface ID."
  value       = aws_network_interface.bfm_eni.id
}

output "target_group_arn" {
  description = "ARN of the BFM target group."
  value       = aws_lb_target_group.bfm_tg.arn
}

output "listener_rule_arn" {
  description = "ARN of the listener rule for host header."
  value       = aws_lb_listener_rule.bfm_rule.arn
}

output "route53_private_record_fqdn" {
  description = "Private DNS FQDN for bfm-<client>.bfm.cloud."
  value       = aws_route53_record.bfm_private.fqdn
}

output "route53_public_remote_fqdn" {
  description = "Public DNS FQDN for bfm-<client>.bfm.cloud (remote)."
  value       = aws_route53_record.bfm_public_remote.fqdn
}

output "route53_public_apex_fqdn" {
  description = "Public apex FQDN for <client>.bfm.cloud (ALB alias)."
  value       = aws_route53_record.bfm_public_apex.fqdn
}

output "cloudflare_remote_record_id" {
  description = "Cloudflare record ID for remote A (if enabled)."
  value       = try(cloudflare_record.cf_bfm_remote[0].id, null)
}

output "cloudflare_apex_record_id" {
  description = "Cloudflare record ID for apex CNAME (if enabled)."
  value       = try(cloudflare_record.cf_bfm_apex[0].id, null)
}

