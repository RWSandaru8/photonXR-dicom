#!/bin/bash

# Test script to verify Orthanc server connection
# Run this on your Linux server to test the setup

echo "🧪 Testing OHIF Viewer and Orthanc connection..."

ORTHANC_URL="https://dentax.globalpearlventures.com:4000"
OHIF_URL="https://dentax.globalpearlventures.com:3000"

echo ""
echo "1. Testing Orthanc server connection..."
if curl -k -u admin:admin123 "$ORTHANC_URL/system" > /dev/null 2>&1; then
    echo "✅ Orthanc server is accessible"
else
    echo "❌ Cannot connect to Orthanc server at $ORTHANC_URL"
    echo "   Check if Orthanc is running and credentials are correct"
fi

echo ""
echo "2. Testing DICOM-Web endpoint..."
if curl -k -u admin:admin123 "$ORTHANC_URL/dicom-web/studies" > /dev/null 2>&1; then
    echo "✅ DICOM-Web endpoint is working"
else
    echo "❌ DICOM-Web endpoint not accessible"
    echo "   Check if DICOMweb plugin is enabled in Orthanc"
fi

echo ""
echo "3. Testing OHIF Viewer server..."
if curl -k "$OHIF_URL/api/health" > /dev/null 2>&1; then
    echo "✅ OHIF Viewer server is running"
else
    echo "❌ OHIF Viewer server not accessible at $OHIF_URL"
    echo "   Check if the Node.js server is running"
fi

echo ""
echo "4. Testing OHIF config endpoint..."
if curl -k "$OHIF_URL/api/config" > /dev/null 2>&1; then
    echo "✅ OHIF config endpoint is working"
else
    echo "❌ OHIF config endpoint not accessible"
fi

echo ""
echo "5. Testing OHIF debug endpoint..."
if curl -k "$OHIF_URL/api/debug" > /dev/null 2>&1; then
    echo "✅ OHIF debug endpoint is working"
    echo "   Debug info:"
    curl -k -s "$OHIF_URL/api/debug" | grep -E '"server"|"orthanc_url"|"proxy_routes"' | head -3
else
    echo "❌ OHIF debug endpoint not accessible"
fi

echo ""
echo "🎯 Complete test results:"
echo "   Orthanc Server: $ORTHANC_URL"
echo "   OHIF Viewer: $OHIF_URL"
echo ""
echo "If all tests pass, your OHIF viewer should work correctly!"
echo "If tests fail, check the logs with: pm2 logs ohif-viewer"
