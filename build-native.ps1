# OHIF Native Build & Serve Script (No Docker) - Windows PowerShell
# This script builds OHIF natively and serves it on port 3000
#
# Usage: .\build-native.ps1 [command]
#
# Commands:
#   install   - Install dependencies
#   build     - Build the application
#   serve     - Serve the built application on port 3000
#   dev       - Start development server
#   clean     - Clean build artifacts
#   full      - Install + Build + Serve
#   start     - Complete setup and start server

param(
    [Parameter(Position=0)]
    [string]$Command = "help"
)

# Configuration
$PORT = 3000
$PUBLIC_URL = "/"
$NODE_ENV = "production"
$APP_CONFIG = "config/orthanc-config.js"

# Colors for output
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Green }
function Write-Warn { param($Message) Write-Host "[WARN] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Step { param($Message) Write-Host "[STEP] $Message" -ForegroundColor Blue }

# Check prerequisites
function Test-Prerequisites {
    Write-Step "Checking prerequisites..."
    
    # Check Node.js
    try {
        $nodeVersion = node --version
        $majorVersion = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        
        if ($majorVersion -lt 18) {
            Write-Error "Node.js version 18 or higher is required. Current version: $nodeVersion"
            Write-Info "Please install Node.js 18+ from https://nodejs.org"
            exit 1
        }
        
        Write-Info "Node.js version: $nodeVersion"
    }
    catch {
        Write-Error "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org"
        exit 1
    }
    
    # Check yarn
    try {
        $yarnVersion = yarn --version
        Write-Info "Yarn version: $yarnVersion"
    }
    catch {
        Write-Info "Yarn not found, installing..."
        npm install -g yarn
    }
    
    # Check if we're in the right directory
    if (-not (Test-Path "package.json") -or -not (Test-Path "platform")) {
        Write-Error "Please run this script from the OHIF project root directory"
        exit 1
    }
    
    Write-Info "Prerequisites check passed"
}

# Install dependencies
function Install-Dependencies {
    Write-Step "Installing dependencies..."
    
    # Clean any existing node_modules
    Write-Info "Cleaning existing node_modules..."
    if (Test-Path "node_modules") {
        Remove-Item -Recurse -Force "node_modules"
    }
    
    # Install dependencies
    Write-Info "Installing project dependencies..."
    yarn install --frozen-lockfile
    
    Write-Info "Dependencies installed successfully"
}

# Setup configuration
function Set-Configuration {
    Write-Step "Setting up configuration..."
    
    # Ensure the config directory exists
    $configDir = "platform\app\public\config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    
    # Copy config from root config/ to platform/app/public/config/
    if (Test-Path "config\orthanc-config.js") {
        Write-Info "Copying Orthanc configuration..."
        Copy-Item "config\orthanc-config.js" "$configDir\orthanc-config.js" -Force
    }
    else {
        Write-Error "Config file not found: config\orthanc-config.js"
        Write-Info "Creating default Orthanc config..."
        New-DefaultConfig
    }
    
    Write-Info "Configuration setup completed"
}

# Create default config if missing
function New-DefaultConfig {
    if (-not (Test-Path "config")) {
        New-Item -ItemType Directory -Path "config" -Force | Out-Null
    }
    
    $defaultConfig = @'
/** @type {AppTypes.Config} */
window.config = {
  name: 'config/orthanc-config.js',
  routerBasename: null,
  extensions: [],
  modes: [],
  customizationService: {},
  showStudyList: true,
  maxNumberOfWebWorkers: 3,
  showWarningMessageForCrossOrigin: true,
  showCPUFallbackMessage: true,
  showLoadingIndicator: true,
  strictZSpacingForVolumeViewport: true,
  
  defaultDataSourceName: 'orthanc',
  
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'orthanc',
      configuration: {
        friendlyName: 'Local Orthanc DICOMWeb Server',
        name: 'Orthanc',
        wadoUriRoot: 'http://localhost:4000/dicom-web',
        qidoRoot: 'http://localhost:4000/dicom-web',
        wadoRoot: 'http://localhost:4000/dicom-web',
        qidoSupportsIncludeField: true,
        supportsReject: true,
        dicomUploadEnabled: true,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: true,
        supportsWildcard: true,
        staticWado: false,
        singlepart: 'bulkdata,video',
        omitQuotationForMultipartRequest: true,
        requestOptions: {
          requestCredentials: 'omit',
        },
        bulkDataURI: {
          enabled: true,
          relativeResolution: 'studies',
        },
      },
    },
  ],
  
  httpErrorHandler: error => {
    console.warn('HTTP Error Status:', error.status);
    if (error.status === 0) {
      console.error('Network error or CORS issue. Please check if Orthanc server is running and CORS is properly configured.');
    }
  },
};
'@
    
    $defaultConfig | Out-File -FilePath "config\orthanc-config.js" -Encoding UTF8
    
    # Copy to build location
    $configDir = "platform\app\public\config"
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }
    Copy-Item "config\orthanc-config.js" "$configDir\orthanc-config.js" -Force
    
    Write-Info "Default Orthanc config created"
}

# Build application
function Build-App {
    Write-Step "Building OHIF application..."
    
    # Setup configuration
    Set-Configuration
    
    # Set environment variables
    $env:NODE_ENV = "production"
    $env:PUBLIC_URL = "/"
    $env:GENERATE_SOURCEMAP = "false"
    $env:NODE_OPTIONS = "--max-old-space-size=4096"
    
    Write-Info "Building with configuration:"
    Write-Info "  NODE_ENV: $($env:NODE_ENV)"
    Write-Info "  PUBLIC_URL: $($env:PUBLIC_URL)"
    Write-Info "  APP_CONFIG: $APP_CONFIG"
    
    # Show current config
    yarn run show:config
    
    # Build the application
    Write-Info "Starting build process..."
    yarn run build
    
    Write-Info "Build completed successfully!"
    Write-Info "Built files are in: platform\app\dist\"
}

# Serve application
function Start-Server {
    Write-Step "Starting OHIF server on port $PORT..."
    
    # Check if build exists
    if (-not (Test-Path "platform\app\dist")) {
        Write-Error "Build directory not found. Please run build first."
        exit 1
    }
    
    # Install serve if not available
    try {
        serve --version | Out-Null
    }
    catch {
        Write-Info "Installing serve globally..."
        npm install -g serve
    }
    
    # Start the server
    Write-Info "=== OHIF Server Starting ==="
    Write-Info "URL: http://localhost:$PORT"
    Write-Info "Build: platform\app\dist\"
    Write-Info "Config: Orthanc on http://localhost:4000"
    Write-Info "============================"
    
    # Serve the application
    Push-Location "platform\app\dist"
    try {
        serve -s . -p $PORT
    }
    finally {
        Pop-Location
    }
}

# Development server
function Start-DevServer {
    Write-Step "Starting development server..."
    
    # Setup configuration
    Set-Configuration
    
    # Set environment variables
    $env:NODE_ENV = "development"
    $env:PUBLIC_URL = "/"
    $env:PORT = $PORT
    
    Write-Info "Starting development server on port $PORT..."
    Write-Info "Development mode - hot reloading enabled"
    
    # Start development server
    Push-Location "platform\app"
    try {
        yarn start
    }
    finally {
        Pop-Location
    }
}

# Clean build artifacts
function Clear-Build {
    Write-Step "Cleaning build artifacts..."
    
    # Remove build directories
    $pathsToRemove = @(
        "platform\app\dist",
        "platform\app\build",
        ".parcel-cache",
        "node_modules\.cache"
    )
    
    foreach ($path in $pathsToRemove) {
        if (Test-Path $path) {
            Remove-Item -Recurse -Force $path
        }
    }
    
    # Remove yarn cache
    yarn cache clean
    
    Write-Info "Clean completed"
}

# Check if Orthanc is running
function Test-Orthanc {
    Write-Step "Checking Orthanc server..."
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4000/system" -TimeoutSec 5
        Write-Info "✓ Orthanc server is running at http://localhost:4000"
        return $true
    }
    catch {
        Write-Warn "✗ Orthanc server is not accessible at http://localhost:4000"
        Write-Info "Please make sure Orthanc server is running with DICOMWeb enabled"
        Write-Info "You can start Orthanc with Docker:"
        Write-Host "  docker run -p 4000:8042 -p 4242:4242 \`" -ForegroundColor Yellow
        Write-Host "    -e ORTHANC__DICOM_WEB__ENABLE=true \`" -ForegroundColor Yellow
        Write-Host "    -e ORTHANC__HTTP_CORS__ENABLED=true \`" -ForegroundColor Yellow
        Write-Host "    orthancteam/orthanc:latest" -ForegroundColor Yellow
        return $false
    }
}

# Show access information
function Show-AccessInfo {
    Write-Info "=== Access Information ==="
    Write-Host "OHIF Viewer:         http://localhost:$PORT" -ForegroundColor White
    Write-Host "Orthanc Web UI:      http://localhost:4000" -ForegroundColor White
    Write-Host "Orthanc DICOMWeb:    http://localhost:4000/dicom-web" -ForegroundColor White
    Write-Host "DICOM C-STORE Port:  4242" -ForegroundColor White
    Write-Host "==========================" -ForegroundColor White
}

# Full deployment
function Start-FullDeployment {
    Write-Step "Starting full native deployment..."
    
    Install-Dependencies
    Build-App
    
    Write-Info "Build completed! You can now:"
    Write-Info "1. Start Orthanc server (if not running)"
    Write-Info "2. Run: .\build-native.ps1 serve"
    
    # Check if Orthanc is running
    Test-Orthanc | Out-Null
    
    Write-Info "Full deployment preparation completed!"
    Write-Info "Run '.\build-native.ps1 serve' to start the server"
}

# Start Orthanc with Docker (helper function)
function Start-Orthanc {
    Write-Step "Starting Orthanc server with Docker..."
    
    try {
        docker --version | Out-Null
    }
    catch {
        Write-Error "Docker is not installed. Please install Docker or start Orthanc manually."
        exit 1
    }
    
    # Stop any existing Orthanc container
    docker stop orthanc-server 2>$null
    docker rm orthanc-server 2>$null
    
    # Start Orthanc
    Write-Info "Starting Orthanc on port 4000..."
    docker run -d `
        --name orthanc-server `
        -p 4000:8042 `
        -p 4242:4242 `
        -v orthanc-db:/var/lib/orthanc/db `
        -v orthanc-storage:/var/lib/orthanc/storage `
        -e ORTHANC__NAME=OHIF-Orthanc `
        -e ORTHANC__DICOM_WEB__ENABLE=true `
        -e ORTHANC__DICOM_WEB__ROOT=/dicom-web/ `
        -e ORTHANC__AUTHENTICATION_ENABLED=false `
        -e ORTHANC__HTTP_CORS__ENABLED=true `
        -e ORTHANC__HTTP_CORS__ALLOWED_ORIGINS=* `
        -e ORTHANC__HTTP_CORS__ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS `
        -e ORTHANC__HTTP_CORS__ALLOWED_HEADERS=* `
        orthancteam/orthanc:latest
    
    Write-Info "Waiting for Orthanc to start..."
    Start-Sleep -Seconds 10
    
    if (Test-Orthanc) {
        Write-Info "Orthanc started successfully!"
    }
    else {
        Write-Error "Failed to start Orthanc"
        exit 1
    }
}

# Main script logic
function Main {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "OHIF Native Build & Serve Script (No Docker)" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    
    switch ($Command.ToLower()) {
        "install" {
            Test-Prerequisites
            Install-Dependencies
        }
        "build" {
            Test-Prerequisites
            Build-App
        }
        "serve" {
            Start-Server
        }
        "dev" {
            Test-Prerequisites
            Start-DevServer
        }
        "clean" {
            Clear-Build
        }
        "full" {
            Test-Prerequisites
            Start-FullDeployment
        }
        "orthanc" {
            Start-Orthanc
        }
        "start" {
            Test-Prerequisites
            Start-FullDeployment
            Write-Host ""
            Write-Info "Starting OHIF server..."
            Start-Server
        }
        default {
            Write-Host "Usage: .\build-native.ps1 [command]" -ForegroundColor White
            Write-Host ""
            Write-Host "Commands:" -ForegroundColor Yellow
            Write-Host "  install   - Install dependencies" -ForegroundColor White
            Write-Host "  build     - Build the application" -ForegroundColor White
            Write-Host "  serve     - Serve the built application on port $PORT" -ForegroundColor White
            Write-Host "  dev       - Start development server with hot reload" -ForegroundColor White
            Write-Host "  clean     - Clean build artifacts" -ForegroundColor White
            Write-Host "  full      - Install + Build (prepare for serving)" -ForegroundColor White
            Write-Host "  orthanc   - Start Orthanc server with Docker" -ForegroundColor White
            Write-Host "  start     - Complete setup: install + build + serve" -ForegroundColor White
            Write-Host "  help      - Show this help message" -ForegroundColor White
            Write-Host ""
            Write-Host "Examples:" -ForegroundColor Yellow
            Write-Host "  .\build-native.ps1 start              # Complete setup and start server" -ForegroundColor White
            Write-Host "  .\build-native.ps1 full; .\build-native.ps1 serve   # Build then serve" -ForegroundColor White
            Write-Host "  .\build-native.ps1 dev                # Development mode" -ForegroundColor White
            Write-Host "  .\build-native.ps1 orthanc            # Start Orthanc server" -ForegroundColor White
            Write-Host ""
            Write-Host "After building, OHIF will be available at:" -ForegroundColor Yellow
            Write-Host "  http://localhost:$PORT" -ForegroundColor White
        }
    }
}

# Run main function
Main
