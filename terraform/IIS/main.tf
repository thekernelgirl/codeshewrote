terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Application = "IIS-WebServer"
    }
  }
}

# Data sources
data "aws_ami" "windows_server" {
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

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "iis_server_role" {
  name = "${var.project_name}-iis-server-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-iis-server-role-${var.environment}"
  }
}

# Attach AWS managed policies
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = aws_iam_role.iis_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_policy" {
  role       = aws_iam_role.iis_server_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# Custom IAM policy for OTEL and telemetry
resource "aws_iam_role_policy" "otel_telemetry_policy" {
  name = "${var.project_name}-iis-otel-policy-${var.environment}"
  role = aws_iam_role.iis_server_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "xray:PutTraceSegments",
          "xray:PutTelemetryRecords"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData"
        ]
        Resource = ["*"]
      }
    ]
  })
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "iis_server_profile" {
  name = "${var.project_name}-iis-server-profile-${var.environment}"
  role = aws_iam_role.iis_server_role.name

  tags = {
    Name = "${var.project_name}-iis-server-profile-${var.environment}"
  }
}

# Security Group for IIS Server
resource "aws_security_group" "iis_server_sg" {
  name        = "${var.project_name}-iis-server-sg-${var.environment}"
  description = "Security group for IIS web server with OTEL"
  vpc_id      = data.aws_vpc.default.id

  # HTTP
  ingress {
    description = "HTTP from allowed CIDR blocks"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # HTTPS
  ingress {
    description = "HTTPS from allowed CIDR blocks"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # RDP
  ingress {
    description = "RDP from allowed CIDR blocks"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # OTEL gRPC
  ingress {
    description = "OTEL gRPC receiver"
    from_port   = 4317
    to_port     = 4317
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # OTEL HTTP
  ingress {
    description = "OTEL HTTP receiver"
    from_port   = 4318
    to_port     = 4318
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # OTEL metrics
  ingress {
    description = "OTEL Prometheus metrics"
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Allow all outbound traffic
  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-iis-server-sg-${var.environment}"
  }
}

# OTEL Collector Configuration File
resource "local_file" "otel_config" {
  filename = "${path.module}/configs/otel-collector-config.yaml"
  content  = <<-EOT
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
  
  hostmetrics:
    collection_interval: 30s
    scrapers:
      cpu:
        metrics:
          system.cpu.utilization:
            enabled: true
      memory:
        metrics:
          system.memory.utilization:
            enabled: true
      disk:
      filesystem:
      network:
      load:
      process:
        mute_process_name_error: true
  
  prometheus:
    config:
      scrape_configs:
        - job_name: 'otel-collector'
          scrape_interval: 30s
          static_configs:
            - targets: ['localhost:8888']

  windowsperfcounters:
    collection_interval: 30s
    perfcounters:
      - object: "Process"
        instances: ["w3wp"]
        counters:
          - name: "% Processor Time"
          - name: "Working Set"
          - name: "Private Bytes"
      - object: "Web Service"
        instances: ["_Total"]
        counters:
          - name: "Current Connections"
          - name: "Total Bytes Received"
          - name: "Total Bytes Sent"
          - name: "Get Requests/sec"
          - name: "Post Requests/sec"
      - object: "ASP.NET Applications"
        instances: ["__Total__"]
        counters:
          - name: "Requests/Sec"
          - name: "Request Execution Time"
          - name: "Requests In Application Queue"

processors:
  batch:
    timeout: 10s
    send_batch_size: 1024
  
  memory_limiter:
    check_interval: 1s
    limit_mib: 512
    spike_limit_mib: 128
  
  resource:
    attributes:
      - key: service.name
        value: ${var.otel_service_name}
        action: upsert
      - key: deployment.environment
        value: ${var.environment}
        action: upsert
      - key: service.instance.id
        from_attribute: host.name
        action: upsert
      - key: cloud.provider
        value: aws
        action: upsert
      - key: cloud.region
        value: ${var.aws_region}
        action: upsert

  resourcedetection:
    detectors: [env, ec2, system]
    timeout: 5s

extensions:
  health_check:
    endpoint: 0.0.0.0:13133
  
  pprof:
    endpoint: 0.0.0.0:1777
  
  zpages:
    endpoint: 0.0.0.0:55679

exporters:
  logging:
    loglevel: info
  
  awsxray:
    region: ${var.aws_region}
  
  awsemf:
    region: ${var.aws_region}
    log_group_name: "/aws/otel/${var.project_name}-${var.environment}"
    log_stream_name: "iis-metrics"
    namespace: "${var.project_name}/${var.environment}"
    dimension_rollup_option: "NoDimensionRollup"
  
  awscloudwatchlogs:
    region: ${var.aws_region}
    log_group_name: "/aws/otel/${var.project_name}-${var.environment}"
    log_stream_name: "iis-logs"
  
  prometheusremotewrite:
    endpoint: http://localhost:9090/api/v1/write
    tls:
      insecure: true

service:
  extensions: [health_check, pprof, zpages]
  
  pipelines:
    traces:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, resource, batch]
      exporters: [logging, awsxray]
    
    metrics:
      receivers: [otlp, hostmetrics, windowsperfcounters, prometheus]
      processors: [memory_limiter, resourcedetection, resource, batch]
      exporters: [logging, awsemf]
    
    logs:
      receivers: [otlp]
      processors: [memory_limiter, resourcedetection, resource, batch]
      exporters: [logging, awscloudwatchlogs]
  
  telemetry:
    logs:
      level: info
    metrics:
      address: 0.0.0.0:8888
EOT
}

# IIS OTEL Instrumentation Config
resource "local_file" "iis_otel_config" {
  filename = "${path.module}/configs/iis-otel-instrumentation.ps1"
  content  = <<-EOT
# IIS OpenTelemetry Auto-Instrumentation Setup
$ErrorActionPreference = "Stop"

Write-Host "=== IIS OpenTelemetry Instrumentation Configuration ===" -ForegroundColor Cyan

# Set environment variables for OTEL auto-instrumentation
$otelVars = @{
    "OTEL_SERVICE_NAME" = "${var.otel_service_name}"
    "OTEL_RESOURCE_ATTRIBUTES" = "deployment.environment=${var.environment},service.namespace=${var.project_name}"
    "OTEL_EXPORTER_OTLP_ENDPOINT" = "http://localhost:4317"
    "OTEL_EXPORTER_OTLP_PROTOCOL" = "grpc"
    "OTEL_TRACES_EXPORTER" = "otlp"
    "OTEL_METRICS_EXPORTER" = "otlp"
    "OTEL_LOGS_EXPORTER" = "otlp"
    "OTEL_DOTNET_AUTO_TRACES_ENABLED" = "true"
    "OTEL_DOTNET_AUTO_METRICS_ENABLED" = "true"
    "OTEL_DOTNET_AUTO_LOGS_ENABLED" = "true"
    "OTEL_DOTNET_AUTO_TRACES_CONSOLE_EXPORTER_ENABLED" = "false"
    "OTEL_DOTNET_AUTO_TRACES_INSTRUMENTATION_ENABLED" = "true"
    "OTEL_DOTNET_AUTO_METRICS_INSTRUMENTATION_ENABLED" = "true"
    "OTEL_DOTNET_AUTO_NETFX_REDIRECT_ENABLED" = "true"
    "COR_ENABLE_PROFILING" = "1"
    "COR_PROFILER" = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    "COR_PROFILER_PATH" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
    "CORECLR_ENABLE_PROFILING" = "1"
    "CORECLR_PROFILER" = "{918728DD-259F-4A6A-AC2B-B85E1B658318}"
    "CORECLR_PROFILER_PATH" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\win-x64\OpenTelemetry.AutoInstrumentation.Native.dll"
    "DOTNET_ADDITIONAL_DEPS" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\AdditionalDeps"
    "DOTNET_SHARED_STORE" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\store"
    "DOTNET_STARTUP_HOOKS" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation\net\OpenTelemetry.AutoInstrumentation.StartupHook.dll"
    "OTEL_DOTNET_AUTO_HOME" = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation"
}

# Set system environment variables
foreach ($key in $otelVars.Keys) {
    [System.Environment]::SetEnvironmentVariable($key, $otelVars[$key], [System.EnvironmentVariableTarget]::Machine)
    Write-Host "Set $key" -ForegroundColor Green
}

# Configure IIS Application Pool to use OTEL
Import-Module WebAdministration

$appPoolName = "DefaultAppPool"
$appPool = Get-Item "IIS:\AppPools\$appPoolName"

# Set environment variables for the app pool
foreach ($key in $otelVars.Keys) {
    $envVar = New-Object System.Collections.Specialized.NameValueCollection
    $envVar.Add($key, $otelVars[$key])
    Set-ItemProperty "IIS:\AppPools\$appPoolName" -Name environmentVariables -Value $envVar
}

Write-Host "Application Pool configured for OTEL instrumentation" -ForegroundColor Green

# Restart IIS to apply changes
Write-Host "Restarting IIS..." -ForegroundColor Yellow
iisreset /restart

Write-Host "=== IIS OTEL Instrumentation Complete ===" -ForegroundColor Cyan
EOT
}

# OTEL Health Check Script
resource "local_file" "otel_health_check" {
  filename = "${path.module}/configs/otel-health-check.ps1"
  content  = <<-EOT
# OTEL Collector Health Check Script
$ErrorActionPreference = "Continue"

Write-Host "`n=== OpenTelemetry Collector Health Check ===" -ForegroundColor Cyan

# Check if OTEL Collector service is running
$otelService = Get-Service -Name "otelcol" -ErrorAction SilentlyContinue
if ($otelService) {
    Write-Host "OTEL Collector Service Status: $($otelService.Status)" -ForegroundColor $(if($otelService.Status -eq 'Running'){'Green'}else{'Red'})
} else {
    Write-Host "OTEL Collector Service: Not Found" -ForegroundColor Red
}

# Check health endpoint
try {
    $healthCheck = Invoke-WebRequest -Uri "http://localhost:13133" -UseBasicParsing -TimeoutSec 5
    Write-Host "Health Check Endpoint: OK (Status: $($healthCheck.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "Health Check Endpoint: FAILED" -ForegroundColor Red
}

# Check OTLP gRPC endpoint
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect("localhost", 4317)
    Write-Host "OTLP gRPC Endpoint (4317): Listening" -ForegroundColor Green
    $tcpClient.Close()
} catch {
    Write-Host "OTLP gRPC Endpoint (4317): Not Accessible" -ForegroundColor Red
}

# Check OTLP HTTP endpoint
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $tcpClient.Connect("localhost", 4318)
    Write-Host "OTLP HTTP Endpoint (4318): Listening" -ForegroundColor Green
    $tcpClient.Close()
} catch {
    Write-Host "OTLP HTTP Endpoint (4318): Not Accessible" -ForegroundColor Red
}

# Check metrics endpoint
try {
    $metrics = Invoke-WebRequest -Uri "http://localhost:8888/metrics" -UseBasicParsing -TimeoutSec 5
    Write-Host "Metrics Endpoint (8888): OK" -ForegroundColor Green
} catch {
    Write-Host "Metrics Endpoint (8888): FAILED" -ForegroundColor Red
}

Write-Host "`n=== Health Check Complete ===`n" -ForegroundColor Cyan
EOT
}

# EC2 Instance with IIS and OTEL
resource "aws_instance" "iis_server" {
  ami                    = data.aws_ami.windows_server.id
  instance_type          = var.instance_type
  subnet_id              = tolist(data.aws_subnets.default.ids)[0]
  vpc_security_group_ids = [aws_security_group.iis_server_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.iis_server_profile.name
  key_name               = var.key_name != "" ? var.key_name : null

  root_block_device {
    volume_size           = 60
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-iis-server-root-volume-${var.environment}"
    }
  }

  user_data = <<-EOT
    <powershell>
    $ErrorActionPreference = "Stop"
    
    # Create logs directory
    New-Item -Path "C:\DeploymentLogs" -ItemType Directory -Force
    Start-Transcript -Path "C:\DeploymentLogs\deployment-$(Get-Date -Format 'yyyyMMdd-HHmmss').log"
    
    Write-Host "=== Starting IIS and OTEL Deployment ===" -ForegroundColor Cyan
    
    # Install IIS with management tools
    Write-Host "Installing IIS..." -ForegroundColor Yellow
    Install-WindowsFeature -Name Web-Server -IncludeManagementTools
    Install-WindowsFeature -Name Web-Asp-Net45
    Install-WindowsFeature -Name Web-Mgmt-Console
    Install-WindowsFeature -Name NET-Framework-45-Core
    Install-WindowsFeature -Name NET-Framework-45-ASPNET
    
    # Install OpenTelemetry Collector
    Write-Host "Installing OpenTelemetry Collector..." -ForegroundColor Yellow
    
    $otelVersion = "0.91.0"
    $otelUrl = "https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v$otelVersion/otelcol-contrib_$($otelVersion)_windows_amd64.tar.gz"
    $otelPath = "C:\Program Files\OpenTelemetry Collector"
    
    New-Item -Path $otelPath -ItemType Directory -Force
    
    # Download and extract OTEL Collector
    $tempFile = "$env:TEMP\otelcol.tar.gz"
    Invoke-WebRequest -Uri $otelUrl -OutFile $tempFile -UseBasicParsing
    
    # Extract using tar (built into Windows Server 2022)
    tar -xzf $tempFile -C $otelPath
    Remove-Item $tempFile
    
    # Create config directory and download config
    $configPath = "$otelPath\config"
    New-Item -Path $configPath -ItemType Directory -Force
    
    # Create OTEL config file
    $otelConfig = @"
${local_file.otel_config.content}
"@
    
    $otelConfig | Out-File -FilePath "$configPath\config.yaml" -Encoding UTF8
    
    # Install OTEL Collector as Windows Service
    New-Service -Name "otelcol" `
                -BinaryPathName "`"$otelPath\otelcol-contrib.exe`" --config=`"$configPath\config.yaml`"" `
                -DisplayName "OpenTelemetry Collector" `
                -Description "OpenTelemetry Collector for IIS monitoring" `
                -StartupType Automatic
    
    # Start OTEL Collector
    Start-Service -Name "otelcol"
    Write-Host "OTEL Collector installed and started" -ForegroundColor Green
    
    # Install .NET OTEL Auto-Instrumentation
    Write-Host "Installing OpenTelemetry .NET Auto-Instrumentation..." -ForegroundColor Yellow
    
    $otelDotNetVersion = "1.2.0"
    $otelDotNetUrl = "https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation/releases/download/v$otelDotNetVersion/opentelemetry-dotnet-instrumentation-windows.zip"
    $otelDotNetPath = "C:\Program Files\OpenTelemetry .NET AutoInstrumentation"
    
    New-Item -Path $otelDotNetPath -ItemType Directory -Force
    
    $tempZip = "$env:TEMP\otel-dotnet.zip"
    Invoke-WebRequest -Uri $otelDotNetUrl -OutFile $tempZip -UseBasicParsing
    Expand-Archive -Path $tempZip -DestinationPath $otelDotNetPath -Force
    Remove-Item $tempZip
    
    Write-Host ".NET Auto-Instrumentation installed" -ForegroundColor Green
    
    # Create IIS landing page with OTEL info
    $html = @"
<!DOCTYPE html>
<html>
<head>
    <title>IIS Server with OpenTelemetry</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            padding: 20px;
        }
        .container {
            max-width: 900px;
            width: 100%;
        }
        h1 { 
            font-size: 3.5em; 
            margin-bottom: 30px;
            text-align: center;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.3);
        }
        .card {
            background: rgba(255,255,255,0.1);
            backdrop-filter: blur(10px);
            padding: 30px;
            border-radius: 15px;
            margin: 20px 0;
            box-shadow: 0 8px 32px 0 rgba(31, 38, 135, 0.37);
            border: 1px solid rgba(255, 255, 255, 0.18);
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 15px;
            margin-top: 20px;
        }
        .info-item {
            background: rgba(255,255,255,0.05);
            padding: 15px;
            border-radius: 10px;
        }
        .info-label {
            font-size: 0.85em;
            opacity: 0.8;
            margin-bottom: 5px;
        }
        .info-value {
            font-size: 1.2em;
            font-weight: bold;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 15px;
            background: #10b981;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
        }
        .endpoints {
            margin-top: 15px;
        }
        .endpoint {
            background: rgba(0,0,0,0.2);
            padding: 10px 15px;
            border-radius: 8px;
            margin: 8px 0;
            font-family: 'Courier New', monospace;
            font-size: 0.9em;
        }
        h2 {
            margin-bottom: 15px;
            font-size: 1.8em;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 IIS + OpenTelemetry</h1>
        
        <div class="card">
            <h2>Server Status</h2>
            <div class="info-grid">
                <div class="info-item">
                    <div class="info-label">Server Name</div>
                    <div class="info-value">$env:COMPUTERNAME</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Status</div>
                    <div class="info-value"><span class="status-badge">ONLINE</span></div>
                </div>
                <div class="info-item">
                    <div class="info-label">Environment</div>
                    <div class="info-value">${var.environment}</div>
                </div>
                <div class="info-item">
                    <div class="info-label">Service</div>
                    <div class="info-value">${var.otel_service_name}</div>
                </div>
            </div>
        </div>
        
        <div class="card">
            <h2>OpenTelemetry Endpoints</h2>
            <div class="endpoints">
                <div class="endpoint">📊 Metrics: http://localhost:8888/metrics</div>
                <div class="endpoint">🔍 Health: http://localhost:13133</div>
                <div class="endpoint">📡 OTLP gRPC: localhost:4317</div>
                <div class="endpoint">🌐 OTLP HTTP: localhost:4318</div>
                <div class="endpoint">📈 zPages: http://localhost:55679/debug/tracez</div>
            </div>
        </div>
        
        <div class="card">
            <h2>Telemetry Features</h2>
            <div class="info-grid">
                <div class="info-item">✅ Distributed Tracing</div>
                <div class="info-item">✅ Metrics Collection</div>
                <div class="info-item">✅ Log Aggregation</div>
                <div class="info-item">✅ AWS X-Ray Export</div>
                <div class="info-item">✅ CloudWatch Integration</div>
                <div class="info-item">✅ IIS Performance Counters</div>
            </div>
        </div>
    </div>
</body>
</html>
"@
    
    $html | Out-File -FilePath C:\inetpub\wwwroot\index.html -Encoding UTF8
    
    # Configure firewall rules
    Write-Host "Configuring firewall rules..." -ForegroundColor Yellow
    New-NetFirewallRule -DisplayName "Allow HTTP" -Direction Inbound -LocalPort 80 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "Allow HTTPS" -Direction Inbound -LocalPort 443 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "OTEL gRPC" -Direction Inbound -LocalPort 4317 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "OTEL HTTP" -Direction Inbound -LocalPort 4318 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "OTEL Metrics" -Direction Inbound -LocalPort 8888 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    New-NetFirewallRule -DisplayName "OTEL Health" -Direction Inbound -LocalPort 13133 -Protocol TCP -Action Allow -ErrorAction SilentlyContinue
    
    # Start and configure IIS
    Write-Host "Starting IIS..." -ForegroundColor Yellow
    Start-Service W3SVC
    Set-Service W3SVC -StartupType Automatic
    
    # Create scheduled task for OTEL health checks
    $action = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument "-File C:\Scripts\otel-health-check.ps1"
    $trigger = New-ScheduledTaskTrigger -Daily -At 9am
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest
    Register-ScheduledTask -TaskName "OTEL-HealthCheck" -Action $action -Trigger $trigger -Principal $principal -Description "Daily OTEL Collector health check"
    
    Write-Host "=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "IIS is running at http://localhost" -ForegroundColor Cyan
    Write-Host "OTEL Collector is running and exporting to AWS CloudWatch and X-Ray" -ForegroundColor Cyan
    
    Stop-Transcript
    </powershell>
  EOT

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  tags = {
    Name              = "${var.project_name}-iis-server-${var.environment}"
    Role              = "WebServer"
    OS                = "WindowsServer2022"
    Observability     = "OpenTelemetry"
    TelemetryExporter = "AWS-CloudWatch-XRay"
  }
}

# Elastic IP
resource "aws_eip" "iis_server_eip" {
  instance = aws_instance.iis_server.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-iis-server-eip-${var.environment}"
  }
}

# CloudWatch Log Group for OTEL
resource "aws_cloudwatch_log_group" "otel_logs" {
  name              = "/aws/otel/${var.project_name}-${var.environment}"
  retention_in_days = 7

  tags = {
    Name        = "${var.project_name}-otel-logs-${var.environment}"
    Application = "IIS-WebServer"
  }
}
