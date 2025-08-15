# Build and run OHIF Viewer with Orthanc Server - Windows PowerShell (Optimized)

Write-Host "🏥 Building OHIF Viewer with Orthanc Server..." -ForegroundColor Green

# Verify all required files are present
Write-Host "🔍 Running pre-build verification..." -ForegroundColor Yellow
& ".\verify-build.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Pre-build verification failed. Please fix the issues above." -ForegroundColor Red
    exit 1
}

# Clean up any existing containers and build cache
Write-Host "📝 Cleaning up existing containers..." -ForegroundColor Yellow
docker-compose down -v 2>$null
docker system prune -f 2>$null

# Build with optimized settings
Write-Host "🔨 Building Docker images (this may take several minutes)..." -ForegroundColor Yellow
$env:DOCKER_BUILDKIT=1
$env:COMPOSE_DOCKER_CLI_BUILD=1

# Build and start services
docker-compose up --build -d

# Wait for services to be ready
Write-Host "⏳ Waiting for services to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Test connectivity
Write-Host "🧪 Testing service connectivity..." -ForegroundColor Yellow

# Test Orthanc
try {
    $orthancResponse = Invoke-WebRequest -Uri "http://localhost:4000" -TimeoutSec 10 -UseBasicParsing
    if ($orthancResponse.StatusCode -eq 200) {
        Write-Host "✅ Orthanc server is running at http://localhost:4000" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  Orthanc server may still be starting up..." -ForegroundColor Yellow
}

# Test OHIF
try {
    $ohifResponse = Invoke-WebRequest -Uri "http://localhost:3000" -TimeoutSec 10 -UseBasicParsing
    if ($ohifResponse.StatusCode -eq 200) {
        Write-Host "✅ OHIF Viewer is running at http://localhost:3000" -ForegroundColor Green
    }
} catch {
    Write-Host "⚠️  OHIF Viewer may still be starting up..." -ForegroundColor Yellow
}

Write-Host "`n🎉 Setup complete!" -ForegroundColor Green
Write-Host "📋 Access points:" -ForegroundColor Cyan
Write-Host "   • OHIF Viewer: http://localhost:3000" -ForegroundColor White
Write-Host "   • Orthanc Server: http://localhost:4000" -ForegroundColor White
Write-Host "   • DICOM Port: localhost:4242" -ForegroundColor White

Write-Host "`n📊 Check status with: docker-compose ps" -ForegroundColor Gray
Write-Host "📝 View logs with: docker-compose logs -f [service-name]" -ForegroundColor Gray
Write-Host "🛑 Stop services with: docker-compose down" -ForegroundColor Gray
