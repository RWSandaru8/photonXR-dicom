#!/bin/bash

# Debug script for specific study
STUDY_UID="1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
SERVER_URL="https://dentax.globalpearlventures.com:3000"
ORTHANC_URL="https://dentax.globalpearlventures.com:4000"

echo "🔍 Debugging Study: $STUDY_UID"
echo "=================================="

# Test 1: Check if study exists in Orthanc directly
echo "1. Checking study in Orthanc directly..."
ORTHANC_RESPONSE=$(curl -k -s "$ORTHANC_URL/dicom-web/studies?StudyInstanceUID=$STUDY_UID")
echo "Response: $ORTHANC_RESPONSE"
if [[ "$ORTHANC_RESPONSE" == "[]" ]]; then
    echo "❌ Study not found in Orthanc!"
elif [[ -z "$ORTHANC_RESPONSE" ]]; then
    echo "❌ No response from Orthanc!"
else
    echo "✅ Study found in Orthanc"
fi

echo ""

# Test 2: Check if study is accessible through proxy
echo "2. Checking study through proxy..."
PROXY_RESPONSE=$(curl -k -s "$SERVER_URL/dicom-web/studies?StudyInstanceUID=$STUDY_UID")
echo "Response: $PROXY_RESPONSE"
if [[ "$PROXY_RESPONSE" == "[]" ]]; then
    echo "❌ Study not found through proxy!"
elif [[ -z "$PROXY_RESPONSE" ]]; then
    echo "❌ No response through proxy!"
else
    echo "✅ Study accessible through proxy"
fi

echo ""

# Test 3: Check OHIF viewer URL
echo "3. Testing OHIF viewer URL..."
VIEWER_URL="$SERVER_URL/viewer/dicomweb?StudyInstanceUIDs=$STUDY_UID"
echo "Viewer URL: $VIEWER_URL"

# Test if the main viewer page loads
VIEWER_RESPONSE=$(curl -k -s -w "%{http_code}" -o /dev/null "$SERVER_URL/viewer/")
echo "Viewer page HTTP status: $VIEWER_RESPONSE"

echo ""

# Test 4: Check series for the study
echo "4. Checking series for the study..."
SERIES_RESPONSE=$(curl -k -s "$SERVER_URL/dicom-web/studies/$STUDY_UID/series")
echo "Series response: $SERIES_RESPONSE"

echo ""

# Test 5: Check server configuration
echo "5. Server configuration check..."
CONFIG_RESPONSE=$(curl -k -s "$SERVER_URL/api/config")
echo "Config response: $CONFIG_RESPONSE"

echo ""

# Test 6: Check if all studies are accessible
echo "6. Checking all studies through proxy..."
ALL_STUDIES=$(curl -k -s "$SERVER_URL/dicom-web/studies")
echo "All studies response: $ALL_STUDIES"

echo ""

# Test 7: Health check
echo "7. Health check..."
HEALTH_RESPONSE=$(curl -k -s "$SERVER_URL/api/health")
echo "Health response: $HEALTH_RESPONSE"

echo ""

# Test 8: Orthanc connectivity test
echo "8. Orthanc connectivity test..."
ORTHANC_TEST=$(curl -k -s "$SERVER_URL/api/test-orthanc")
echo "Orthanc test response: $ORTHANC_TEST"
