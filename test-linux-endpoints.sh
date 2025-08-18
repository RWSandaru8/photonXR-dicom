#!/bin/bash

# Test DICOM endpoints on Linux server
echo "🧪 Testing DICOM endpoints..."

BASE_URL="https://dentax.globalpearlventures.com:3000"
ORTHANC_URL="https://dentax.globalpearlventures.com:4000"

echo "1. Testing basic connectivity..."
echo "🔍 Health check:"
curl -k -s "$BASE_URL/api/health" | jq . || echo "❌ Health check failed"

echo -e "\n🔍 Orthanc system info:"
curl -k -s "$ORTHANC_URL/system" | jq . || echo "❌ Orthanc system failed"

echo -e "\n2. Testing DICOM-Web endpoints..."

# Get studies from Orthanc directly
echo "🔍 Getting studies from Orthanc directly:"
STUDIES=$(curl -k -s "$ORTHANC_URL/studies")
echo "Studies found: $(echo $STUDIES | jq '. | length')"

if [ "$(echo $STUDIES | jq '. | length')" -gt 0 ]; then
    FIRST_STUDY_ID=$(echo $STUDIES | jq -r '.[0]')
    echo "First study ID: $FIRST_STUDY_ID"

    # Get study details
    STUDY_DETAILS=$(curl -k -s "$ORTHANC_URL/studies/$FIRST_STUDY_ID")
    STUDY_UID=$(echo $STUDY_DETAILS | jq -r '.MainDicomTags.StudyInstanceUID')
    echo "Study UID: $STUDY_UID"

    echo -e "\n3. Testing DICOM-Web endpoints through proxy:"

    echo "🔍 Testing /dicom-web/studies:"
    curl -k -s -H "Accept: application/dicom+json" "$BASE_URL/dicom-web/studies" | jq . || echo "❌ Failed"

    echo -e "\n🔍 Testing /dicom-web/studies?StudyInstanceUID=$STUDY_UID:"
    curl -k -s -H "Accept: application/dicom+json" "$BASE_URL/dicom-web/studies?StudyInstanceUID=$STUDY_UID" | jq . || echo "❌ Failed"

    echo -e "\n🔍 Testing /dicom-web/studies/$STUDY_UID:"
    curl -k -s -H "Accept: application/dicom+json" "$BASE_URL/dicom-web/studies/$STUDY_UID" | jq . || echo "❌ Failed"

    echo -e "\n🔍 Testing /dicom-web/studies/$STUDY_UID/metadata:"
    curl -k -s -H "Accept: application/dicom+json" "$BASE_URL/dicom-web/studies/$STUDY_UID/metadata" | jq . || echo "❌ Failed"

    echo -e "\n🔍 Testing /dicom-web/studies/$STUDY_UID/series:"
    curl -k -s -H "Accept: application/dicom+json" "$BASE_URL/dicom-web/studies/$STUDY_UID/series" | jq . || echo "❌ Failed"

    echo -e "\n4. Testing custom debug endpoint:"
    echo "🔍 Testing custom study endpoint:"
    curl -k -s "$BASE_URL/api/test-study-endpoint/$STUDY_UID" | jq . || echo "❌ Failed"

    echo -e "\n5. Testing WADO-URI endpoint:"
    # Get series and instance info for WADO-URI test
    SERIES_DATA=$(curl -k -s "$ORTHANC_URL/dicom-web/studies/$STUDY_UID/series")
    if [ "$(echo $SERIES_DATA | jq '. | length')" -gt 0 ]; then
        SERIES_UID=$(echo $SERIES_DATA | jq -r '.[0]["0020000E"].Value[0]')
        echo "First series UID: $SERIES_UID"

        INSTANCES_DATA=$(curl -k -s "$ORTHANC_URL/dicom-web/studies/$STUDY_UID/series/$SERIES_UID/instances")
        if [ "$(echo $INSTANCES_DATA | jq '. | length')" -gt 0 ]; then
            INSTANCE_UID=$(echo $INSTANCES_DATA | jq -r '.[0]["00080018"].Value[0]')
            echo "First instance UID: $INSTANCE_UID"

            echo "🔍 Testing WADO-URI:"
            WADO_URL="$BASE_URL/wado?requestType=WADO&studyUID=$STUDY_UID&seriesUID=$SERIES_UID&objectUID=$INSTANCE_UID&contentType=application/dicom"
            echo "WADO URL: $WADO_URL"
            curl -k -s -I "$WADO_URL" || echo "❌ WADO-URI failed"
        fi
    fi

    echo -e "\n6. Generate OHIF URL:"
    echo "🌐 OHIF Viewer URL: $BASE_URL/viewer/dicomweb?StudyInstanceUIDs=$STUDY_UID"
else
    echo "❌ No studies found in Orthanc"
fi

echo -e "\n7. Server logs (last 20 lines):"
echo "📋 PM2 logs:"
pm2 logs ohif-viewer --lines 20 --nostream || echo "❌ No PM2 logs available"

echo -e "\n✅ Test completed!"
