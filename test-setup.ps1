# Test script to verify OHIF and Orthanc setup
Write-Host "Testing OHIF and Orthanc Setup..." -ForegroundColor Green

# Function to test HTTP endpoint
function Test-Endpoint {
    param([string]$Url, [string]$Name)
    
    try {
        $response = Invoke-WebRequest -Uri $Url -TimeoutSec 10 -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✓ $Name is accessible" -ForegroundColor Green
            return $true
        }
    }
    catch {
        Write-Host "✗ $Name is not accessible: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    return $false
}

# Function to check if container is running
function Test-Container {
    param([string]$ContainerName)
    
    $container = docker ps --filter "name=$ContainerName" --format "{{.Names}}"
    if ($container -eq $ContainerName) {
        Write-Host "✓ Container '$ContainerName' is running" -ForegroundColor Green
        return $true
    } else {
        Write-Host "✗ Container '$ContainerName' is not running" -ForegroundColor Red
        return $false
    }
}

Write-Host "`n--- Container Status ---" -ForegroundColor Cyan
$ohifRunning = Test-Container "ohif-viewer"
$orthancRunning = Test-Container "orthanc-server"

Write-Host "`n--- Network Connectivity ---" -ForegroundColor Cyan
$orthancWeb = Test-Endpoint "http://localhost:4000" "Orthanc Web Interface"
$orthancApi = Test-Endpoint "http://localhost:4000/dicom-web/studies" "Orthanc DICOMWeb API"
$ohifWeb = Test-Endpoint "http://localhost:3000" "OHIF Viewer"

Write-Host "`n--- Summary ---" -ForegroundColor Cyan
if ($ohifRunning -and $orthancRunning -and $orthancWeb -and $orthancApi -and $ohifWeb) {
    Write-Host "✓ All services are running correctly!" -ForegroundColor Green
    Write-Host "You can now:" -ForegroundColor Yellow
    Write-Host "  - Access OHIF Viewer at: http://localhost:3000" -ForegroundColor Yellow
    Write-Host "  - Access Orthanc Web UI at: http://localhost:4000" -ForegroundColor Yellow
    Write-Host "  - Upload DICOM files via Orthanc Web UI" -ForegroundColor Yellow
} else {
    Write-Host "✗ Some services are not working correctly" -ForegroundColor Red
    Write-Host "Please check the logs:" -ForegroundColor Yellow
    Write-Host "  docker logs ohif-viewer" -ForegroundColor Yellow
    Write-Host "  docker logs orthanc-server" -ForegroundColor Yellow
}

Write-Host "`nPress any key to continue..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
