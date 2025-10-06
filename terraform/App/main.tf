terraform {
  required_version = ">= 1.1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

# 🔥 Use the sherpa CLI profile for all AWS actions
provider "aws" {
  profile = "sherpa"
  region  = var.aws_region

  default_tags {
    tags = {
      Environment   = var.environment
      ManagedBy     = "Terraform"
      Application   = "BFM-AppServer"
      Platform      = "Windows"
      sherpa:ec2    = "true"
      sherpa:type   = "BFM"
      sherpa:client = var.client_code
    }
  }
}

# Optional: Cloudflare provider (only used if enable_cloudflare = true)
provider "cloudflare" {
  api_token = var.cloudflare_api_token
  alias     = "cf"
}

# ============================================
# AMI lookup – Find latest Windows Server 2022
# ============================================
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

# ===========================
# ENI – we tag it up front 💅
# ===========================
resource "aws_network_interface" "bfm_eni" {
  subnet_id         = var.subnet_id_a
  private_ips       = var.private_ip != "" ? [var.private_ip] : null
  security_groups   = var.security_group_ids
  source_dest_check = true

  tags = merge(
    var.tags_common,
    {
      Name           = "eni-bfm-${var.client_code}-${var.environment}"
      sherpa:role    = "bfm-app-eni"
      sherpa:client  = var.client_code
    }
  )
}

# ===========================
# EC2 instance – Windows W22
# ===========================
resource "aws_instance" "bfm_app" {
  ami                         = data.aws_ami.windows_server_2022.id
  instance_type               = var.ec2_bfm_type
  iam_instance_profile        = var.iam_instance_profile_arn
  network_interface {
    network_interface_id = aws_network_interface.bfm_eni.id
    device_index         = 0
  }

  # Root (C:) – gp3, 80 GB, encrypted via KMS
  root_block_device {
    volume_size = var.ebs_mapping.bfm.root_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id

    tags = {
      Name          = "bfm-${var.client_code}-root-${var.environment}"
      sherpa:client = var.client_code
      sherpa:disk   = "root"
    }
  }

  # Data (E:) – gp3, 60 GB, encrypted via KMS
  ebs_block_device {
    device_name = var.ebs_mapping.bfm.data_device_name
    volume_size = var.ebs_mapping.bfm.data_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id

    tags = {
      Name          = "bfm-${var.client_code}-data-${var.environment}"
      sherpa:client = var.client_code
      sherpa:disk   = "data"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # 🌶️ Rename host, prep IIS, SSL, drive E:, deploy content, generate healthcheck
  user_data = <<-EOT
    <powershell>
    $ErrorActionPreference = "Stop"

    # --- Basics ---
    tzutil /s "${var.windows_time_zone}"
    Write-Host "Installing NFS client..."
    Add-WindowsCapability -Online -Name "ClientForNFS*"
    Write-Host "Disabling Defender real-time protection..."
    Set-MpPreference -DisableRealtimeMonitoring $true -DisableIOAVProtection $true
    Write-Host "Disabling Windows Defender feature..."
    Uninstall-WindowsFeature -Name Windows-Defender

    # --- Hostname ---
    $newName = "bfm-${var.client_code}-${var.environment}"
    Rename-Computer -NewName $newName -Force

    # --- Local Admin Users ---
    foreach ($u in ${jsonencode(var.user_mapping)}) {
      $user = $u.username
      $pass = (ConvertTo-SecureString $u.password -AsPlainText -Force)
      if (-not (Get-LocalUser -Name $user -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $user -Password $pass -FullName $user -Description "BFM local admin"
      }
      Add-LocalGroupMember -Group "Administrators" -Member $user -ErrorAction SilentlyContinue
    }
    # Service Principal (SP) account
    $spUser = "${var.sp_account.username}"
    $spPass = (ConvertTo-SecureString "${var.sp_account.password}" -AsPlainText -Force)
    if (-not (Get-LocalUser -Name $spUser -ErrorAction SilentlyContinue)) {
      New-LocalUser -Name $spUser -Password $spPass -FullName $spUser -Description "BFM SP account"
    }
    Add-LocalGroupMember -Group "Administrators" -Member $spUser -ErrorAction SilentlyContinue

    # --- RDP SSL Cert from gateway share ---
    New-PSDrive -Name "G" -PSProvider FileSystem -Root "\\${var.gateway_share_host}\${var.gateway_share_path}" -Persist -ErrorAction SilentlyContinue
    $certPath = "G:\\${var.rdp_cert_filename}"
    if (Test-Path $certPath) {
      $cert = Import-PfxCertificate -FilePath $certPath -CertStoreLocation Cert:\\LocalMachine\\My -Password (ConvertTo-SecureString "${var.rdp_cert_password}" -AsPlainText -Force)
      New-Item -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp" -ErrorAction SilentlyContinue
      $thumb = $cert.Thumbprint
      Set-ItemProperty -Path "HKLM:\\SYSTEM\\CurrentControlSet\\Control\\Terminal Server\\WinStations\\RDP-Tcp" -Name "SSLCertificateSHA1Hash" -Value $thumb
    }

    # --- Initialize and format E: ---
    $disk = Get-Disk | Where-Object PartitionStyle -eq "RAW" | Select-Object -First 1
    if ($disk) {
      Initialize-Disk -Number $disk.Number -PartitionStyle GPT
      $part = New-Partition -DiskNumber $disk.Number -UseMaximumSize -DriveLetter "E"
      Format-Volume -Partition $part -FileSystem NTFS -NewFileSystemLabel "BFMData" -Confirm:$false
    }

    # --- Pull bfmacd0.zip from gateway ---
    $zipSrc = "G:\\${var.bfm_zip_filename}"
    $zipDest = "E:\\bfm\\${var.bfm_zip_filename}"
    New-Item -Path "E:\\bfm" -ItemType Directory -Force
    if (Test-Path $zipSrc) { Copy-Item $zipSrc $zipDest -Force }

    # --- IIS install & site layout ---
    Install-WindowsFeature -Name Web-Server,Web-Asp-Net45,Web-Mgmt-Console,NET-Framework-45-Core,NET-Framework-45-ASPNET
    New-Item -Path "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0" -ItemType Directory -Force
    New-Item -Path "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_dev" -ItemType Directory -Force
    New-Item -Path "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_tst" -ItemType Directory -Force

    # Deploy content (example unzip)
    if (Test-Path $zipDest) {
      Expand-Archive -Path $zipDest -DestinationPath "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0" -Force
      Copy-Item -Path "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0\\*" -Destination "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_dev" -Recurse -Force
      Copy-Item -Path "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0\\*" -Destination "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_tst" -Recurse -Force
    }

    Import-Module WebAdministration
    $siteName = "BFM-${var.client_code}"
    $ip = (Invoke-RestMethod -Uri http://169.254.169.254/latest/meta-data/local-ipv4)
    New-Website -Name $siteName -PhysicalPath "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0" -IPAddress $ip -Port 443 -Ssl
    # Bind SSL cert if present
    if ($cert) {
      New-WebBinding -Name $siteName -Protocol https -Port 443 -IPAddress $ip
      Push-Location IIS:\\SslBindings
      Get-ChildItem | Where-Object { $_.Sites -contains $siteName } | Remove-Item -ErrorAction SilentlyContinue
      New-Item "0.0.0.0!443" -Thumbprint $cert.Thumbprint -SSLFlags 1
      Pop-Location
    }

    # Healthcheck
    $healthPath = "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0\\healthcheck.html"
    "<html><body><h1>OK - ${var.client_code}</h1></body></html>" | Out-File -FilePath $healthPath -Encoding UTF8 -Force

    # IIS applications and web.config templating per env
    New-WebApplication -Site $siteName -Name "bfm${var.client_code}" -PhysicalPath "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0"
    New-WebApplication -Site $siteName -Name "bfm${var.client_code}_dev" -PhysicalPath "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_dev"
    New-WebApplication -Site $siteName -Name "bfm${var.client_code}_tst" -PhysicalPath "E:\\inetpub_${var.client_code}\\wwwroot\\bfmacd0_tst"

    # Install SSMS + Webroot agent from gateway (example silent installs)
    $ssms = "G:\\${var.ssms_installer}"
    $webroot = "G:\\${var.webroot_installer}"
    if (Test-Path $ssms) { Start-Process $ssms -ArgumentList "/quiet" -Wait }
    if (Test-Path $webroot) { Start-Process $webroot -ArgumentList "/quiet" -Wait }

    Write-Host "BFM Application Server setup complete."
    </powershell>
  EOT

  tags = merge(
    var.tags_common,
    {
      Name           = "bfm-${var.client_code}-${var.environment}"
      sherpa:type    = "BFM"
      sherpa:client  = var.client_code
      Platform       = "Windows"
    }
  )

  depends_on = [aws_network_interface.bfm_eni]
}

# ===========================
# Elastic IP – tag the EIP 🌶️
# ===========================
resource "aws_eip" "bfm_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.bfm_eni.id

  tags = merge(
    var.tags_common,
    {
      Name           = "eip-bfm-${var.client_code}-${var.environment}"
      sherpa:role    = "bfm-app-eip"
      sherpa:client  = var.client_code
    }
  )
}

# =================================================
# Route 53 – private and public A records for BFM 🧭
# =================================================
# Private record: bfm-<client>.bfm.cloud -> instance private IP
resource "aws_route53_record" "bfm_private" {
  zone_id = var.route53_private_zone_id
  name    = "bfm-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_network_interface.bfm_eni.private_ip]
}

# Public record (remote/RDC): bfm-<client>.bfm.cloud -> EIP
resource "aws_route53_record" "bfm_public_remote" {
  zone_id = var.route53_public_zone_id
  name    = "bfm-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_eip.bfm_eip.public_ip]
}

# Public apex: <client>.bfm.cloud -> ELB alias (ALB DNS name + hosted zone)
resource "aws_route53_record" "bfm_public_apex" {
  zone_id = var.route53_public_zone_id
  name    = "${var.client_code}.bfm.cloud"
  type    = "A"

  alias {
    name                   = var.alb_dns_name
    zone_id                = var.alb_hosted_zone_id
    evaluate_target_health = true
  }
}

# ===========================================
# Cloudflare – mirror public DNS (optional) ⚡
# ===========================================
resource "cloudflare_record" "cf_bfm_remote" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "bfm-${var.client_code}.bfm.cloud"
  type    = "A"
  value   = aws_eip.bfm_eip.public_ip
  ttl     = 120
  proxied = false
}

resource "cloudflare_record" "cf_bfm_apex" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "${var.client_code}.bfm.cloud"
  type    = "CNAME"
  value   = var.alb_dns_name
  ttl     = 120
  proxied = false
}

# ==============================================
# ALB Target Group + Listener Rule (HTTPS:443) 🔊
# ==============================================
resource "aws_lb_target_group" "bfm_tg" {
  name        = "tg-bfm-${var.client_code}-${var.environment}"
  port        = 443
  protocol    = "HTTPS"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    protocol            = "HTTPS"
    path                = "/healthcheck.html"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }

  tags = merge(
    var.tags_common,
    {
      Name           = "tg-bfm-${var.client_code}-${var.environment}"
      sherpa:client  = var.client_code
      sherpa:role    = "bfm-tg"
    }
  )
}

# Register the instance to the TG
resource "aws_lb_target_group_attachment" "bfm_tg_attach" {
  target_group_arn = aws_lb_target_group.bfm_tg.arn
  target_id        = aws_instance.bfm_app.id
  port             = 443
}

# Listener rule for host header <client>.bfm.cloud
resource "aws_lb_listener_rule" "bfm_rule" {
  listener_arn = var.alb_listener_arn
  priority     = var.alb_rule_priority

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bfm_tg.arn
  }

  condition {
    host_header {
      values = ["${var.client_code}.bfm.cloud"]
    }
  }

  tags = {
    Name          = "lr-bfm-${var.client_code}-${var.environment}"
    sherpa:client = var.client_code
    sherpa:role   = "bfm-listener-rule"
  }
}

