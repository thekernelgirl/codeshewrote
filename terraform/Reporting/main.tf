terraform {
  required_version = ">= 1.3.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  profile = "sherpa"
  region  = var.aws_region

  default_tags {
    tags = merge(var.tags_common, {
      Application   = "Report-Server"
      Platform      = "Windows"
      sherpa:type   = "RS"
      sherpa:client = var.client_code
    })
  }
}

provider "cloudflare" {
  alias     = "cf"
  api_token = var.cloudflare_api_token
}

data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_network_interface" "rs_eni" {
  subnet_id       = var.subnet_id
  security_groups = var.security_group_ids

  tags = {
    Name          = "eni-rs-${var.client_code}-${var.environment}"
    sherpa:role   = "rs-eni"
    sherpa:client = var.client_code
  }
}

resource "aws_instance" "rs_server" {
  ami                    = data.aws_ami.windows_server_2022.id
  instance_type          = var.ec2_rs_type
  key_name               = var.key_name
  iam_instance_profile   = var.iam_instance_profile_arn

  network_interface {
    network_interface_id = aws_network_interface.rs_eni.id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
  }

  # Bootstrap via SSM cuz inline is bad
  tags = {
    Name          = "rs-${var.client_code}-${var.environment}"
    sherpa:type   = "RS"
    sherpa:client = var.client_code
    Platform      = "Windows"
  }
}

resource "aws_eip" "rs_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.rs_eni.id

  tags = {
    Name          = "eip-rs-${var.client_code}-${var.environment}"
    sherpa:role   = "rs-eip"
    sherpa:client = var.client_code
  }
}

# Apex RS record (im guessing here)
resource "aws_route53_record" "rs_apex" {
  zone_id = var.route53_public_zone_id
  name    = "rs-${var.client_code}.bfm.cloud"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

# RDC record or something
resource "aws_route53_record" "rs_rdc" {
  zone_id = var.route53_public_zone_id
  name    = "rdc-rs-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_eip.rs_eip.public_ip]
}

resource "cloudflare_record" "cf_rs_rdc" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "rdc-rs-${var.client_code}.bfm.cloud"
  type    = "A"
  value   = aws_eip.rs_eip.public_ip
  ttl     = 120
  proxied = false
}

resource "cloudflare_record" "cf_rs_apex" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "rs-${var.client_code}.bfm.cloud"
  type    = "CNAME"
  value   = var.alb_dns_name
  ttl     = 120
  proxied = false
}

resource "aws_lb_target_group" "rs_tg" {
  name        = "tg-rs-${var.client_code}-${var.environment}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_lb_target_group_attachment" "rs_attach" {
  target_group_arn = aws_lb_target_group.rs_tg.arn
  target_id        = aws_instance.rs_server.id
  port             = 443
}

resource "aws_lb_listener_rule" "rs_rule" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rs_tg.arn
  }

  condition {
    host_header {
      values = ["rs-${var.client_code}.bfm.cloud"]
    }
  }
}

