# Test DICOM endpoints that are failing

$baseUrl = "https://dentax.globalpearlventures.com:3000"
$orthancUrl = "https://dentax.globalpearlventures.com:4000"

Write-Host "Testing DICOM-Web endpoints..." -ForegroundColor Green

# First, get list of studies from Orthanc directly
Write-Host "`n1. Getting studies from Orthanc directly:" -ForegroundColor Yellow
try {
    $orthancStudies = Invoke-RestMethod -Uri "$orthancUrl/studies" -Method GET -SkipCertificateCheck
    Write-Host "Found $($orthancStudies.Count) studies in Orthanc"

    if ($orthancStudies.Count -gt 0) {
        $firstStudyId = $orthancStudies[0]
        Write-Host "First study ID: $firstStudyId"

        # Get study details
        $studyDetails = Invoke-RestMethod -Uri "$orthancUrl/studies/$firstStudyId" -Method GET -SkipCertificateCheck
        $studyUID = $studyDetails.MainDicomTags.StudyInstanceUID
        Write-Host "Study UID: $studyUID"

        # Test DICOM-Web endpoints through proxy
        Write-Host "`n2. Testing DICOM-Web endpoints through proxy:" -ForegroundColor Yellow

        $endpoints = @(
            "/dicom-web/studies",
            "/dicom-web/studies?StudyInstanceUID=$studyUID",
            "/dicom-web/studies/$studyUID",
            "/dicom-web/studies/$studyUID/metadata",
            "/dicom-web/studies/$studyUID/series"
        )

        foreach ($endpoint in $endpoints) {
            Write-Host "`nTesting: $baseUrl$endpoint" -ForegroundColor Cyan
            try {
                $response = Invoke-WebRequest -Uri "$baseUrl$endpoint" -Method GET -SkipCertificateCheck -Headers @{
                    "Accept" = "application/dicom+json"
                    "User-Agent" = "OHIF-Viewer/3.0"
                }
                Write-Host "Status: $($response.StatusCode)" -ForegroundColor Green
                Write-Host "Content-Type: $($response.Headers.'Content-Type')"

                if ($response.Content.Length -lt 1000) {
                    Write-Host "Response: $($response.Content)"
                } else {
                    Write-Host "Response length: $($response.Content.Length) characters"
                }
            }
            catch {
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                if ($_.Exception.Response) {
                    Write-Host "Status: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
                    try {
                        $errorContent = $_.Exception.Response.GetResponseStream()
                        $reader = New-Object System.IO.StreamReader($errorContent)
                        $errorText = $reader.ReadToEnd()
                        Write-Host "Error content: $errorText" -ForegroundColor Red
                    }
                    catch {
                        Write-Host "Could not read error content"
                    }
                }
            }
        }

        # Test our custom debug endpoint
        Write-Host "`n3. Testing custom debug endpoint:" -ForegroundColor Yellow
        try {
            $debugUrl = "$baseUrl/api/test-study-endpoint/$studyUID"
            Write-Host "Testing: $debugUrl" -ForegroundColor Cyan
            $debugResponse = Invoke-RestMethod -Uri $debugUrl -Method GET -SkipCertificateCheck
            Write-Host "Debug response received - check server logs for details"
        }
        catch {
            Write-Host "Debug endpoint error: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Error getting studies from Orthanc: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "`n4. Testing health endpoints:" -ForegroundColor Yellow
@("/api/health", "/api/orthanc-info") | ForEach-Object {
    try {
        Write-Host "Testing: $baseUrl$_" -ForegroundColor Cyan
        $response = Invoke-RestMethod -Uri "$baseUrl$_" -Method GET -SkipCertificateCheck
        Write-Host "✓ Success" -ForegroundColor Green
    }
    catch {
        Write-Host "✗ Failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nTest completed. Check the server logs for detailed proxy information." -ForegroundColor Green
