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
}

provider "cloudflare" {
  alias     = "cf"
  api_token = var.cloudflare_api_token
}

data "aws_ami" "al3" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"] # adjust to arm64 if needed
  }
}

resource "aws_network_interface" "sftp_eni" {
  subnet_id       = var.subnet_id_c
  security_groups = var.security_group_ids

  tags = {
    Name          = "eni-sftp-${var.client_code}-${var.environment}"
    sherpa:role   = "sftp-eni"
    sherpa:client = var.client_code
  }
}

resource "aws_instance" "sftp" {
  ami           = data.aws_ami.al3.id
  instance_type = var.instance_type
  key_name      = var.key_name

  network_interface {
    network_interface_id = aws_network_interface.sftp_eni.id
    device_index         = 0
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    device_name = "/dev/xvda"
    encrypted   = true
    kms_key_id  = var.kms_key_id
  }

  user_data = <<-EOT
    #!/bin/bash
    set -xe
    timedatectl set-timezone ${var.linux_timezone}
    hostnamectl set-hostname sftp-${var.client_code}-${var.environment}
    dnf -y update

    # Create SFTP user
    useradd ${var.sftp_user}
    echo "${var.sftp_user}:${var.sftp_password}" | chpasswd

    # Allow password auth
    sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
    systemctl restart sshd
  EOT

  tags = {
    Name          = "sftp-${var.client_code}-${var.environment}"
    sherpa:type   = "SFTP"
    sherpa:client = var.client_code
    Platform      = "Linux"
  }

  depends_on = [aws_network_interface.sftp_eni]
}

resource "aws_eip" "sftp_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.sftp_eni.id

  tags = {
    Name          = "eip-sftp-${var.client_code}-${var.environment}"
    sherpa:role   = "sftp-eip"
    sherpa:client = var.client_code
  }
}

resource "aws_route53_record" "sftp_private" {
  zone_id = var.route53_private_zone_id
  name    = "sftp-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_network_interface.sftp_eni.private_ip]
}

resource "aws_route53_record" "sftp_public" {
  zone_id = var.route53_public_zone_id
  name    = "sftp-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_eip.sftp_eip.public_ip]
}

resource "cloudflare_record" "cf_sftp_public" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "sftp-${var.client_code}.bfm.cloud"
  type    = "A"
  value   = aws_eip.sftp_eip.public_ip
  ttl     = 120
  proxied = false
}

resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "sftp-${var.client_code}-${var.environment}-${var.aws_region}"
  force_destroy = true

  tags = {
    Name          = "sftp-bucket-${var.client_code}-${var.environment}"
    sherpa:role   = "sftp-bucket"
    sherpa:client = var.client_code
  }
}

resource "aws_storagegateway_nfs_file_share" "sftp_share" {
  client_list        = var.sftp_client_list
  gateway_arn        = var.storage_gateway_arn
  location_arn       = aws_s3_bucket.sftp_bucket.arn
  role_arn           = var.storage_gateway_role_arn
  default_storage_class = "S3_STANDARD"

  tags = {
    Name          = "sftp-share-${var.client_code}-${var.environment}"
    sherpa:role   = "sftp-share"
    sherpa:client = var.client_code
  }
}

