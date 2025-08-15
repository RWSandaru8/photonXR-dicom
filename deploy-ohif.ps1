# OHIF + Orthanc Production Build & Deployment Script (Windows PowerShell)
# This script provides backup, build, and deployment functionality
#
# Usage: .\deploy-ohif.ps1 [command]
#
# Commands:
#   build     - Build the Docker images
#   start     - Start the services
#   stop      - Stop the services
#   restart   - Restart the services
#   backup    - Backup Orthanc data
#   restore   - Restore Orthanc data from backup
#   logs      - Show logs
#   status    - Show service status
#   clean     - Clean up everything
#   full      - Full deployment (backup + build + start)

param(
    [Parameter(Position=0)]
    [string]$Command = "help",
    
    [Parameter(Position=1)]
    [string]$Timestamp = ""
)

# Configuration
$ProjectName = "ohif-dicom"
$BackupDir = "./backups"
$TimeStamp = Get-Date -Format "yyyyMMdd_HHmmss"
$ComposeFile = "docker-compose.yml"
$ProdComposeFile = "docker-compose.prod.yml"

# Colors for output
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Step { param($Message) Write-Host "[STEP] $Message" -ForegroundColor Blue }

# Check prerequisites
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Error "Docker is not installed or not in PATH"
        exit 1
    }
    
    if (-not (Get-Command docker-compose -ErrorAction SilentlyContinue)) {
        Write-Error "Docker Compose is not installed or not in PATH"
        exit 1
    }
    
    # Check if Docker daemon is running
    try {
        docker info | Out-Null
        Write-Info "Prerequisites check passed"
    }
    catch {
        Write-Error "Docker daemon is not running"
        exit 1
    }
}

# Create backup directory
function Initialize-BackupDirectory {
    if (-not (Test-Path $BackupDir)) {
        New-Item -ItemType Directory -Path $BackupDir | Out-Null
    }
    Write-Info "Backup directory ready: $BackupDir"
}

# Backup function
function Start-Backup {
    Write-Step "Starting backup process..."
    Initialize-BackupDirectory
    
    # Check if volumes exist
    $volumes = docker volume ls --format "{{.Name}}" | Where-Object { $_ -like "*orthanc*" }
    
    if ($volumes -contains "${ProjectName}_orthanc-db") {
        Write-Info "Backing up Orthanc database..."
        docker run --rm `
            -v "${ProjectName}_orthanc-db:/data" `
            -v "${PWD}/${BackupDir}:/backup" `
            alpine tar czf "/backup/orthanc-db-${TimeStamp}.tar.gz" -C /data .
        
        Write-Info "Database backup completed: orthanc-db-${TimeStamp}.tar.gz"
    }
    else {
        Write-Warn "Orthanc database volume not found, skipping database backup"
    }
    
    if ($volumes -contains "${ProjectName}_orthanc-storage") {
        Write-Info "Backing up Orthanc storage..."
        docker run --rm `
            -v "${ProjectName}_orthanc-storage:/data" `
            -v "${PWD}/${BackupDir}:/backup" `
            alpine tar czf "/backup/orthanc-storage-${TimeStamp}.tar.gz" -C /data .
        
        Write-Info "Storage backup completed: orthanc-storage-${TimeStamp}.tar.gz"
    }
    else {
        Write-Warn "Orthanc storage volume not found, skipping storage backup"
    }
    
    # Backup configuration
    Write-Info "Backing up configuration..."
    $configFiles = @(
        "config",
        "orthanc-config",
        "docker-compose.yml",
        "docker-compose.prod.yml",
        "Dockerfile"
    ) | Where-Object { Test-Path $_ }
    
    if ($configFiles.Count -gt 0) {
        Compress-Archive -Path $configFiles -DestinationPath "$BackupDir/config-${TimeStamp}.zip" -Force
        Write-Info "Configuration backup completed: config-${TimeStamp}.zip"
    }
    else {
        Write-Warn "No configuration files found to backup"
    }
    
    Write-Info "Backup process completed successfully"
}

# Restore function
function Start-Restore {
    param($RestoreTimestamp)
    
    Write-Step "Starting restore process..."
    
    if ([string]::IsNullOrEmpty($RestoreTimestamp)) {
        Write-Error "Please specify timestamp for restore (format: YYYYMMDD_HHMMSS)"
        Write-Info "Available backups:"
        Get-ChildItem "$BackupDir/*.tar.gz", "$BackupDir/*.zip" -ErrorAction SilentlyContinue | Format-Table Name, Length, LastWriteTime
        exit 1
    }
    
    Write-Warn "This will overwrite existing data. Continue? (y/N)"
    $confirm = Read-Host
    if ($confirm -notmatch '^[Yy]$') {
        Write-Info "Restore cancelled"
        exit 0
    }
    
    # Stop services first
    Stop-Services
    
    # Restore database
    $dbBackup = "$BackupDir/orthanc-db-${RestoreTimestamp}.tar.gz"
    if (Test-Path $dbBackup) {
        Write-Info "Restoring Orthanc database..."
        docker run --rm `
            -v "${ProjectName}_orthanc-db:/data" `
            -v "${PWD}/${BackupDir}:/backup" `
            alpine sh -c "rm -rf /data/* && tar xzf /backup/orthanc-db-${RestoreTimestamp}.tar.gz -C /data"
        Write-Info "Database restore completed"
    }
    else {
        Write-Warn "Database backup not found: $dbBackup"
    }
    
    # Restore storage
    $storageBackup = "$BackupDir/orthanc-storage-${RestoreTimestamp}.tar.gz"
    if (Test-Path $storageBackup) {
        Write-Info "Restoring Orthanc storage..."
        docker run --rm `
            -v "${ProjectName}_orthanc-storage:/data" `
            -v "${PWD}/${BackupDir}:/backup" `
            alpine sh -c "rm -rf /data/* && tar xzf /backup/orthanc-storage-${RestoreTimestamp}.tar.gz -C /data"
        Write-Info "Storage restore completed"
    }
    else {
        Write-Warn "Storage backup not found: $storageBackup"
    }
    
    Write-Info "Restore process completed"
}

# Build function
function Start-Build {
    Write-Step "Building Docker images..."
    
    # Check if config files exist
    if (-not (Test-Path "platform/app/public/config/orthanc-config.js")) {
        if (Test-Path "config/orthanc-config.js") {
            Write-Info "Copying config from config/ to platform/app/public/config/"
            New-Item -ItemType Directory -Path "platform/app/public/config" -Force | Out-Null
            Copy-Item "config/orthanc-config.js" "platform/app/public/config/"
        }
        else {
            Write-Error "Orthanc config file not found in config/ or platform/app/public/config/"
            exit 1
        }
    }
    
    # Build with BuildKit for better performance
    $env:DOCKER_BUILDKIT = 1
    $env:COMPOSE_DOCKER_CLI_BUILD = 1
    
    Write-Info "Building OHIF Viewer image..."
    docker-compose build --no-cache --parallel ohif-viewer
    
    Write-Info "Pulling Orthanc image..."
    docker-compose pull orthanc
    
    Write-Info "Build completed successfully"
}

# Start services
function Start-Services {
    Write-Step "Starting services..."
    
    # Choose compose file based on SSL cert existence
    $composeCmd = "docker-compose"
    if ((Test-Path "C:/ssl") -or (Test-Path "/etc/letsencrypt/live") -and ($env:USE_SSL -eq "true")) {
        Write-Info "SSL certificates found, using production configuration"
        $composeCmd = "docker-compose -f $ProdComposeFile"
    }
    
    Invoke-Expression "$composeCmd up -d"
    
    # Wait for services to be healthy
    Write-Info "Waiting for services to become healthy..."
    Start-Sleep -Seconds 30
    
    # Check service health
    Test-Health
    
    Write-Info "Services started successfully"
    Show-AccessInfo
}

# Stop services
function Stop-Services {
    Write-Step "Stopping services..."
    docker-compose down
    Write-Info "Services stopped"
}

# Restart services
function Restart-Services {
    Write-Step "Restarting services..."
    Stop-Services
    Start-Services
}

# Check health
function Test-Health {
    Write-Step "Checking service health..."
    
    # Check OHIF
    try {
        Invoke-RestMethod -Uri "http://localhost:3000/health" -TimeoutSec 5 | Out-Null
        Write-Info "✓ OHIF Viewer is healthy"
    }
    catch {
        Write-Warn "✗ OHIF Viewer health check failed"
    }
    
    # Check Orthanc
    try {
        Invoke-RestMethod -Uri "http://localhost:4000/system" -TimeoutSec 5 | Out-Null
        Write-Info "✓ Orthanc server is healthy"
    }
    catch {
        Write-Warn "✗ Orthanc server health check failed"
    }
}

# Show access information
function Show-AccessInfo {
    Write-Info "=== Access Information ==="
    Write-Host "OHIF Viewer (HTTP):  http://localhost:3000" -ForegroundColor White
    Write-Host "Orthanc Web UI:      http://localhost:4000" -ForegroundColor White
    Write-Host "Orthanc DICOMWeb:    http://localhost:4000/dicom-web" -ForegroundColor White
    Write-Host "DICOM C-STORE Port:  4242" -ForegroundColor White
    
    if ((Test-Path "C:/ssl") -or (Test-Path "/etc/letsencrypt/live") -and ($env:USE_SSL -eq "true")) {
        Write-Host "OHIF Viewer (HTTPS): https://dentax.globalpearlventures.com:3443" -ForegroundColor White
    }
    
    Write-Host "==========================" -ForegroundColor White
}

# Show logs
function Show-Logs {
    param($ServiceName)
    
    Write-Step "Showing service logs..."
    if ([string]::IsNullOrEmpty($ServiceName)) {
        docker-compose logs -f
    }
    else {
        docker-compose logs -f $ServiceName
    }
}

# Show status
function Show-Status {
    Write-Step "Service Status:"
    docker-compose ps
    
    Write-Step "Container Resource Usage:"
    $containers = docker-compose ps -q
    if ($containers) {
        docker stats --no-stream $containers
    }
    else {
        Write-Info "No running containers"
    }
    
    Write-Step "Volume Usage:"
    $volumes = docker volume ls --format "table {{.Name}}\t{{.Driver}}\t{{.CreatedAt}}" | Where-Object { $_ -like "*$ProjectName*" }
    if ($volumes) {
        $volumes
    }
    else {
        Write-Info "No project volumes found"
    }
}

# Clean up everything
function Start-Clean {
    Write-Step "Cleaning up everything..."
    
    Write-Warn "This will remove all containers, images, and volumes. Continue? (y/N)"
    $confirm = Read-Host
    if ($confirm -notmatch '^[Yy]$') {
        Write-Info "Clean cancelled"
        exit 0
    }
    
    # Stop and remove everything
    docker-compose down -v --rmi all --remove-orphans
    
    # Clean up dangling images
    docker image prune -f
    docker volume prune -f
    
    Write-Info "Cleanup completed"
}

# Full deployment
function Start-FullDeployment {
    Write-Step "Starting full deployment..."
    
    Start-Backup
    Start-Build
    Start-Services
    
    Write-Info "Full deployment completed successfully!"
}

# Main script logic
function Main {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "OHIF + Orthanc Production Deployment Script" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    Test-Prerequisites
    
    switch ($Command.ToLower()) {
        "build" { Start-Build }
        "start" { Start-Services }
        "stop" { Stop-Services }
        "restart" { Restart-Services }
        "backup" { Start-Backup }
        "restore" { Start-Restore $Timestamp }
        "logs" { Show-Logs $Timestamp }
        "status" { Show-Status }
        "health" { Test-Health }
        "clean" { Start-Clean }
        "full" { Start-FullDeployment }
        default {
            Write-Host "Usage: .\deploy-ohif.ps1 [command]" -ForegroundColor White
            Write-Host ""
            Write-Host "Commands:" -ForegroundColor Yellow
            Write-Host "  build     - Build Docker images" -ForegroundColor White
            Write-Host "  start     - Start services" -ForegroundColor White
            Write-Host "  stop      - Stop services" -ForegroundColor White
            Write-Host "  restart   - Restart services" -ForegroundColor White
            Write-Host "  backup    - Backup Orthanc data and config" -ForegroundColor White
            Write-Host "  restore   - Restore from backup (requires timestamp)" -ForegroundColor White
            Write-Host "  logs      - Show logs (optional: specify service name)" -ForegroundColor White
            Write-Host "  status    - Show service status and resource usage" -ForegroundColor White
            Write-Host "  health    - Check service health" -ForegroundColor White
            Write-Host "  clean     - Clean up everything (destructive!)" -ForegroundColor White
            Write-Host "  full      - Full deployment (backup + build + start)" -ForegroundColor White
            Write-Host "  help      - Show this help message" -ForegroundColor White
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\deploy-ohif.ps1 full                    # Complete deployment" -ForegroundColor White
            Write-Host "  .\deploy-ohif.ps1 backup                 # Backup data" -ForegroundColor White
            Write-Host "  .\deploy-ohif.ps1 restore 20240815_143000 # Restore from specific backup" -ForegroundColor White
            Write-Host "  .\deploy-ohif.ps1 logs ohif-viewer       # Show OHIF logs" -ForegroundColor White
            Write-Host "  .\deploy-ohif.ps1 logs orthanc-server    # Show Orthanc logs" -ForegroundColor White
            Write-Host ""
            Write-Host "Environment variables:" -ForegroundColor Yellow
            Write-Host "  `$env:USE_SSL='true'              # Enable SSL mode" -ForegroundColor White
        }
    }
}

# Run main function
Main
