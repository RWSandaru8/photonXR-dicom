#!/bin/bash

# Debug script for specific study
STUDY_UID="11.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
SERVER_URL="https://dentax.globalpearlventures.com:3000"
ORTHANC_URL="https://dentax.globalpearlventures.com:4000"

echo "🔍 Debugging Study: $STUDY_UID"
echo "=================================="

# Test 1: Check if study exists in Orthanc directly
echo "1. Checking study in Orthanc directly..."
curl -k -s "$ORTHANC_URL/dicom-web/studies?StudyInstanceUID=$STUDY_UID" | jq '.'

echo ""

# Test 2: Check if study is accessible through proxy
echo "2. Checking study through proxy..."
curl -k -s "$SERVER_URL/dicom-web/studies?StudyInstanceUID=$STUDY_UID" | jq '.'

echo ""

# Test 3: Check OHIF viewer URL
echo "3. Testing OHIF viewer URL..."
VIEWER_URL="$SERVER_URL/viewer/dicomweb?StudyInstanceUIDs=$STUDY_UID"
echo "Viewer URL: $VIEWER_URL"

echo ""

# Test 4: Check series for the study
echo "4. Checking series for the study..."
curl -k -s "$SERVER_URL/dicom-web/studies/$STUDY_UID/series" | jq '.'

echo ""

# Test 5: Check server logs (if accessible)
echo "5. Server configuration check..."
curl -k -s "$SERVER_URL/api/config" | jq '.dataSources[0].configuration'
