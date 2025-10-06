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

# Use sherpa thingy and attach default tags that fit DB role
provider "aws" {
  profile = "sherpa"
  region  = var.aws_region

  default_tags {
    tags = merge(var.tags_common, {
      Application   = "App-DB-Server"
      Platform      = "Linux"
      sherpa:type   = "DB"
      sherpa:client = var.client_code
    })
  }
}

provider "cloudflare" {
  alias     = "cf"
  api_token = var.cloudflare_api_token
}

data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_network_interface" "db_eni" {
  subnet_id       = var.subnet_id_b
  security_groups = var.security_group_ids
  private_ips     = var.private_ip != "" ? [var.private_ip] : null

  tags = merge(var.tags_common, {
    Name          = "eni-db-${var.client_code}-${var.environment}"
    sherpa:role   = "db-eni"
    sherpa:client = var.client_code
  })
}

resource "aws_instance" "db_server" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = var.db_instance_type
  key_name      = var.key_name
  iam_instance_profile = var.iam_instance_profile_arn

  # Attach ENI
  network_interface {
    network_interface_id = aws_network_interface.db_eni.id
    device_index         = 0
  }

  # Root volume (30 GB gp3 + KMS)
  root_block_device {
    volume_size = var.ebs_mapping.db.root_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
    tags = {
      Name        = "db-${var.client_code}-root-${var.environment}"
      sherpa:disk = "root"
    }
  }

  # Data volume (/sqldata)
  ebs_block_device {
    device_name = var.ebs_mapping.db.data_device_name
    volume_size = var.ebs_mapping.db.data_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
    tags = {
      Name        = "db-${var.client_code}-sqldata-${var.environment}"
      sherpa:disk = "sqldata"
    }
  }

  # Logs volume (/sqllogs)
  ebs_block_device {
    device_name = var.ebs_mapping.db.logs_device_name
    volume_size = var.ebs_mapping.db.logs_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
    tags = {
      Name        = "db-${var.client_code}-sqllogs-${var.environment}"
      sherpa:disk = "sqllogs"
    }
  }

  # Backup volume (/backup)
  ebs_block_device {
    device_name = var.ebs_mapping.db.backup_device_name
    volume_size = var.ebs_mapping.db.backup_gb
    volume_type = "gp3"
    encrypted   = true
    kms_key_id  = var.kms_key_id
    tags = {
      Name        = "db-${var.client_code}-backup-${var.environment}"
      sherpa:disk = "backup"
    }
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  # Hostname I assume is like like db-e19.bfm.cloud (alias db-<client_short>.bfm.cloud)
  user_data = <<-EOT
    #!/bin/bash
    set -euxo pipefail

    # Sensible things that you should do first
    timedatectl set-timezone ${var.linux_timezone}
    hostnamectl set-hostname db-${var.client_code}-${var.environment}.bfm.cloud
    apt-get update -y
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

    # Format/mount vols
    mkfs.ext4 ${var.ebs_mapping.db.data_device_name}   || true
    mkfs.ext4 ${var.ebs_mapping.db.logs_device_name}   || true
    mkfs.ext4 ${var.ebs_mapping.db.backup_device_name} || true

    mkdir -p /sqldata /sqllogs /backup /backup/create /backup/scripts

    echo "${var.ebs_mapping.db.data_device_name}  /sqldata  ext4  defaults,nofail  0 2"  >> /etc/fstab
    echo "${var.ebs_mapping.db.logs_device_name}  /sqllogs  ext4  defaults,nofail  0 2"  >> /etc/fstab
    echo "${var.ebs_mapping.db.backup_device_name} /backup  ext4  defaults,nofail  0 2" >> /etc/fstab

    mount -a

    #Install SQL Server or something 
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | apt-key add -
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/mssql-server-2022.list)" || true
    add-apt-repository "$(wget -qO- https://packages.microsoft.com/config/ubuntu/22.04/prod.list)" || true
    apt-get update -y

    MSSQL_PID=${var.sql_edition}
    DEBIAN_FRONTEND=noninteractive apt-get install -y mssql-server
    /opt/mssql/bin/mssql-conf -n set sqlagent.enabled true
    /opt/mssql/bin/mssql-conf -n set memory.memorylimitmb ${var.sql_memory_max_mb}
    /opt/mssql/bin/mssql-conf -n set filelocation.defaultdatadir /sqldata
    /opt/mssql/bin/mssql-conf -n set filelocation.defaultlogdir /sqllogs
    systemctl enable mssql-server
    systemctl restart mssql-server

    # Tools (I assume sqlcmd/bcp 18.x)
    ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' >> /etc/profile.d/mssql.sh
    source /etc/profile.d/mssql.sh

    # Ensure mssql owns the data/log/backup dirs, because thats bad if it doesnt
    chown -R mssql:mssql /sqldata /sqllogs /backup

    # do some awscli because terminal yes
    apt-get install -y unzip curl
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
    unzip -o /tmp/awscliv2.zip -d /tmp
    /tmp/aws/install

    # Help Cron to stuff for S3
    aws s3 cp s3://${var.admin_scripts_bucket}/${var.admin_scripts_prefix}/ /backup/scripts/ --recursive

    # Template zip password into environment for scripts for sanity
    echo "DBZIPPASS=${var.db_zip_password}" > /etc/dbzip.env
    chmod 600 /etc/dbzip.env

    # Cron some other stuff at scheduled times that make sense
    crontab -l 2>/dev/null | { cat; echo "10 * * * * . /etc/profile; . /etc/dbzip.env; /backup/scripts/daily.sh >> /var/log/backup_daily.log 2>&1"; } | crontab -
    crontab -l 2>/dev/null | { cat; echo "40 * * * * . /etc/profile; . /etc/dbzip.env; /backup/scripts/daily2.sh >> /var/log/backup_daily2.log 2>&1"; } | crontab -
    crontab -l 2>/dev/null | { cat; echo "0 4 * * 0 . /etc/profile; . /etc/dbzip.env; /backup/scripts/weekly.sh >> /var/log/backup_weekly.log 2>&1"; } | crontab -
    crontab -l 2>/dev/null | { cat; echo "0 3 1 * * . /etc/profile; . /etc/dbzip.env; /backup/scripts/monthly.sh >> /var/log/backup_monthly.log 2>&1"; } | crontab -
    
    # Get latest backups, again for sanity
    mkdir -p /backup/create
    aws s3 cp s3://${var.db_backup_bucket}/${var.bfm_backup_prefix}/ /backup/create/ --recursive --exclude "*" --include "bfmacd0_Daily*.zip"
    aws s3 cp s3://${var.db_backup_bucket}/${var.obj_backup_prefix}/ /backup/create/ --recursive --exclude "*" --include "bfmacd0obj_Daily*.zip"
    for z in /backup/create/*.zip; do
      [ -f "$z" ] && unzip -o -P "${var.db_zip_password}" "$z" -d /backup/create/
    done

    cat > /tmp/bootstrap.sql <<'SQL'
    -- Enable Agent/DB Mail XPs
    EXEC sp_configure 'show advanced options', 1; RECONFIGURE;
    EXEC sp_configure 'Database Mail XPs', 1; RECONFIGURE;

    DECLARE @nm sysname = 'db-${var.client_code}-${var.environment}.bfm.cloud';
    EXEC sp_dropserver @@SERVERNAME, 'droplogins';
    EXEC sp_addserver @nm, 'local';

    ALTER DATABASE tempdb MODIFY FILE (NAME = tempdev, FILENAME = '/sqldata/tempdb.mdf');
    ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = '/sqllogs/templog.ldf');
    
    # HEY Kenny Logins 
    ${join("\n", [
      for l in var.sql_logins : "CREATE LOGIN [" .. l.name .. "] WITH PASSWORD = '" .. l.password .. "', CHECK_POLICY = OFF;"
    ])}

    EXEC msdb.dbo.sysmail_add_account_sp
      @account_name = 'ses-mail',
      @email_address = '${var.ses_from_email}',
      @display_name = 'DB Mail',
      @mailserver_name = '${var.ses_smtp_host}',
      @port = ${var.ses_smtp_port},
      @username = '${var.ses_smtp_user}',
      @password = '${var.ses_smtp_password}',
      @enable_ssl = 1;

    EXEC msdb.dbo.sysmail_add_profile_sp @profile_name = 'DefaultProfile';
    EXEC msdb.dbo.sysmail_add_profileaccount_sp @profile_name = 'DefaultProfile', @account_name = 'ses-mail', @sequence_number = 1;
    EXEC msdb.dbo.sysmail_add_principalprofile_sp @profile_name = 'DefaultProfile', @principal_id = 0, @is_default = 1;
    SQL

    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${var.sa_password}" -i /tmp/bootstrap.sql || true

    systemctl restart mssql-server

    # Find most recent archives and restore and get some coffee
    latest_bfm=$(ls -1t /backup/create/bfmacd0_Daily*.bak 2>/dev/null | head -n1 || true)
    latest_obj=$(ls -1t /backup/create/bfmacd0obj_Daily*.bak 2>/dev/null | head -n1 || true)

    cat > /tmp/restore.sql <<'SQL'
    -- Restore BFM prod/dev/tst
    :setvar BFMNAME bfm${var.client_short}
    :setvar BFMDEV  bfm${var.client_short}_dev
    :setvar BFMTST  bfm${var.client_short}_tst

    -- Example RESTORE (paths should match extracted .bak locations)
    -- RESTORE DATABASE $(BFMNAME) FROM DISK = N'$(latest_bfm)' WITH REPLACE, RECOVERY;
    -- RESTORE DATABASE $(BFMDEV)  FROM DISK = N'$(latest_bfm)' WITH REPLACE, RECOVERY;
    -- RESTORE DATABASE $(BFMTST)  FROM DISK = N'$(latest_bfm)' WITH REPLACE, RECOVERY;

    -- Set FULL recovery for prod/tst
    -- ALTER DATABASE $(BFMNAME) SET RECOVERY FULL;
    -- ALTER DATABASE $(BFMTST)  SET RECOVERY FULL;

    -- Restore OBJ DB
    :setvar OBJNAME bfm${var.client_short}obj
    -- RESTORE DATABASE $(OBJNAME) FROM DISK = N'$(latest_obj)' WITH REPLACE, RECOVERY;
    SQL

    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${var.sa_password}" -i /tmp/restore.sql || true

    # more awscli magic
    aws s3 cp s3://${var.admin_scripts_bucket}/${var.admin_jobs_prefix}/ /tmp/jobs/ --recursive
    for f in /tmp/jobs/*.sql; do
      [ -f "$f" ] && /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "${var.sa_password}" -i "$f"
    done

    # I think we are almost done
    echo "DB server bootstrap completed."
  EOT

  tags = merge(var.tags_common, {
    Name           = "db-${var.client_code}-${var.environment}"
    sherpa:ec2     = "true"
    sherpa:client  = var.client_code
    sherpa:type    = "DB"
    Platform       = "Linux"
  })

  depends_on = [aws_network_interface.db_eni]
}

resource "aws_eip" "db_eip" {
  domain            = "vpc"
  network_interface = aws_network_interface.db_eni.id

  tags = merge(var.tags_common, {
    Name          = "eip-db-${var.client_code}-${var.environment}"
    sherpa:role   = "db-eip"
    sherpa:client = var.client_code
  })
}

# Private A(just guessing here): db-<client>.bfm.cloud -> private IP
resource "aws_route53_record" "db_private_a" {
  zone_id = var.route53_private_zone_id
  name    = "db-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_network_interface.db_eni.private_ip]
}

# Private CNAME(Just guessing here again): db-<short>.bfm.cloud -> db-<client>.bfm.cloud
resource "aws_route53_record" "db_private_cname" {
  zone_id = var.route53_private_zone_id
  name    = "db-${var.client_short}.bfm.cloud"
  type    = "CNAME"
  ttl     = 60
  records = [aws_route53_record.db_private_a.fqdn]
}

# Public A: db-<client>.bfm.cloud -> EIP
resource "aws_route53_record" "db_public_a" {
  zone_id = var.route53_public_zone_id
  name    = "db-${var.client_code}.bfm.cloud"
  type    = "A"
  ttl     = 60
  records = [aws_eip.db_eip.public_ip]
}

# Public CNAME: db-<short>.bfm.cloud -> db-<client>.bfm.cloud
resource "aws_route53_record" "db_public_cname" {
  zone_id = var.route53_public_zone_id
  name    = "db-${var.client_short}.bfm.cloud"
  type    = "CNAME"
  ttl     = 60
  records = [aws_route53_record.db_public_a.fqdn]
}

resource "cloudflare_record" "cf_db_public_a" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "db-${var.client_code}.bfm.cloud"
  type    = "A"
  value   = aws_eip.db_eip.public_ip
  ttl     = 120
  proxied = false
}

resource "cloudflare_record" "cf_db_public_cname" {
  provider = cloudflare.cf
  count    = var.enable_cloudflare ? 1 : 0

  zone_id = var.cloudflare_zone_id
  name    = "db-${var.client_short}.bfm.cloud"
  type    = "CNAME"
  value   = "db-${var.client_code}.bfm.cloud"
  ttl     = 120
  proxied = false
}

resource "aws_s3_bucket" "db_bucket" {
  bucket        = var.db_s3_bucket_name
  force_destroy = var.db_s3_bucket_force_destroy

  tags = merge(var.tags_common, {
    Name          = "db-bucket-${var.client_code}-${var.environment}"
    sherpa:role   = "db-backups"
    sherpa:client = var.client_code
  })
}

# Create some "folders"
resource "aws_s3_bucket_object" "db_folder_weekly" {
  bucket = aws_s3_bucket.db_bucket.id
  key    = "${var.db_s3_prefix}/weekly/"
}

resource "aws_s3_bucket_object" "db_folder_monthly" {
  bucket = aws_s3_bucket.db_bucket.id
  key    = "${var.db_s3_prefix}/monthly/"
}

resource "aws_s3_bucket_object" "db_folder_yearly" {
  bucket = aws_s3_bucket.db_bucket.id
  key    = "${var.db_s3_prefix}/yearly/"
}

resource "aws_s3_bucket_lifecycle_configuration" "db_lifecycle" {
  bucket = aws_s3_bucket.db_bucket.id

  rule {
    id     = "weekly-expire"
    status = "Enabled"

    filter {
      prefix = "${var.db_s3_prefix}/weekly/"
    }

    expiration {
      days = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "monthly-expire"
    status = "Enabled"

    filter {
      prefix = "${var.db_s3_prefix}/monthly/"
    }

    expiration {
      days = 31
    }

    noncurrent_version_expiration {
      noncurrent_days = 31
    }
  }

  rule {
    id     = "yearly-expire"
    status = "Enabled"

    filter {
      prefix = "${var.db_s3_prefix}/yearly/"
    }

    expiration {
      days = 365
    }

    noncurrent_version_expiration {
      noncurrent_days = 365
    }
  }
}

