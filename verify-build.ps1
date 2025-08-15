# Pre-build verification script for OHIF Docker build
Write-Host "🔍 Verifying all required files are present..." -ForegroundColor Green

# Define required files and directories
$requiredFiles = @(
    "package.json",
    "yarn.lock",
    "preinstall.js",
    "lerna.json",
    "platform\app\public\config\orthanc-config.js",
    ".docker\compressDist.sh",
    ".docker\Viewer-v3.x\entrypoint.sh",
    ".docker\Viewer-v3.x\default.conf.template"
)

$requiredDirectories = @(
    "addOns",
    "extensions",
    "modes", 
    "platform",
    "orthanc-config"
)

# Check files
$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (-not (Test-Path $file)) {
        $missingFiles += $file
        Write-Host "❌ Missing file: $file" -ForegroundColor Red
    } else {
        Write-Host "✅ Found file: $file" -ForegroundColor Green
    }
}

# Check directories
$missingDirectories = @()
foreach ($dir in $requiredDirectories) {
    if (-not (Test-Path $dir -PathType Container)) {
        $missingDirectories += $dir
        Write-Host "❌ Missing directory: $dir" -ForegroundColor Red
    } else {
        Write-Host "✅ Found directory: $dir" -ForegroundColor Green
    }
}

# Check package.json files in extensions and modes
$packageJsonDirs = @()
Get-ChildItem "extensions" -Directory | ForEach-Object { $packageJsonDirs += "extensions\$($_.Name)" }
Get-ChildItem "modes" -Directory | ForEach-Object { $packageJsonDirs += "modes\$($_.Name)" }
Get-ChildItem "platform" -Directory | ForEach-Object { $packageJsonDirs += "platform\$($_.Name)" }

$missingPackageJson = @()
foreach ($dir in $packageJsonDirs) {
    $packageFile = "$dir\package.json"
    if (-not (Test-Path $packageFile)) {
        $missingPackageJson += $packageFile
        Write-Host "⚠️  Missing package.json: $packageFile" -ForegroundColor Yellow
    }
}

# Summary
Write-Host "`n📊 Verification Summary:" -ForegroundColor Cyan
if ($missingFiles.Count -eq 0 -and $missingDirectories.Count -eq 0) {
    Write-Host "✅ All required files and directories are present!" -ForegroundColor Green
    Write-Host "🚀 Ready to build Docker image!" -ForegroundColor Green
    
    if ($missingPackageJson.Count -gt 0) {
        Write-Host "⚠️  Note: Some package.json files are missing, but this may not prevent the build" -ForegroundColor Yellow
    }
    
    exit 0
} else {
    Write-Host "❌ Build verification failed!" -ForegroundColor Red
    Write-Host "Missing files: $($missingFiles.Count)" -ForegroundColor Red
    Write-Host "Missing directories: $($missingDirectories.Count)" -ForegroundColor Red
    
    if ($missingFiles.Count -gt 0) {
        Write-Host "`nMissing files:" -ForegroundColor Red
        $missingFiles | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    if ($missingDirectories.Count -gt 0) {
        Write-Host "`nMissing directories:" -ForegroundColor Red
        $missingDirectories | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    }
    
    Write-Host "`nPlease ensure all required files are present before building." -ForegroundColor Red
    exit 1
}
