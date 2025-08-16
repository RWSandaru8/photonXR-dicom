#!/bin/bash

# Test script to verify the specific study exists in Orthanc
STUDY_UID="1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
ORTHANC_URL="https://dentax.globalpearlventures.com:4000"
OHIF_URL="https://dentax.globalpearlventures.com:3000"

echo "🔍 Testing OHIF Study Access"
echo "=============================="
echo "Study UID: $STUDY_UID"
echo ""

echo "1. 📡 Testing direct Orthanc access..."
echo "   Checking if study exists in Orthanc..."
if curl -k -u admin:admin123 -s "$ORTHANC_URL/dicom-web/studies/$STUDY_UID" > /dev/null 2>&1; then
    echo "   ✅ Study found in Orthanc"
else
    echo "   ❌ Study NOT found in Orthanc"
    echo "   URL tested: $ORTHANC_URL/dicom-web/studies/$STUDY_UID"
    echo ""
    echo "   Let's check what studies are available:"
    curl -k -u admin:admin123 -s "$ORTHANC_URL/dicom-web/studies" | head -20
fi

echo ""
echo "2. 🌐 Testing OHIF proxy access..."
echo "   Checking if OHIF can proxy to the study..."
if curl -k -s "$OHIF_URL/dicom-web/studies/$STUDY_UID" > /dev/null 2>&1; then
    echo "   ✅ OHIF proxy can access study"
else
    echo "   ❌ OHIF proxy cannot access study"
    echo "   This might be an authentication or proxy issue"
fi

echo ""
echo "3. 📋 Testing OHIF configuration..."
echo "   Getting OHIF config..."
CONFIG_RESPONSE=$(curl -k -s "$OHIF_URL/api/config")
if echo "$CONFIG_RESPONSE" | grep -q "orthanc"; then
    echo "   ✅ OHIF config contains Orthanc settings"
    echo "   Data source: $(echo "$CONFIG_RESPONSE" | grep -o '"qidoRoot":"[^"]*"')"
else
    echo "   ❌ OHIF config does not contain Orthanc settings"
    echo "   Config response: $CONFIG_RESPONSE"
fi

echo ""
echo "4. 🔧 Testing OHIF debug endpoint..."
DEBUG_RESPONSE=$(curl -k -s "$OHIF_URL/api/debug")
echo "   Debug info: $DEBUG_RESPONSE"

echo ""
echo "5. 📊 Final recommendations:"
if curl -k -u admin:admin123 -s "$ORTHANC_URL/dicom-web/studies/$STUDY_UID" > /dev/null 2>&1; then
    echo "   ✅ Study exists in Orthanc"
    echo "   ✅ You should be able to view it at:"
    echo "      $OHIF_URL/viewer/dicomweb?StudyInstanceUIDs=$STUDY_UID"
    echo ""
    echo "   If you still see CloudFront URLs, run: ./fix-config.sh"
else
    echo "   ❌ Study not found in Orthanc"
    echo "   Check if the Study UID is correct or if the study was uploaded properly"
fi
