#!/bin/bash

# OHIF Viewer Testing Script
# Tests server connectivity, Orthanc connection, and configuration

set -e

echo "🧪 OHIF Viewer Testing Suite"
echo "================================"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuration
SERVER_URL="https://dentax.globalpearlventures.com:3000"
ORTHANC_URL="https://dentax.globalpearlventures.com:4000"

# Test 1: Server Health Check
echo "🔍 Testing server health..."
if curl -k -s "$SERVER_URL/api/health" > /dev/null; then
    echo -e "${GREEN}✅ Server health check passed${NC}"
    curl -k -s "$SERVER_URL/api/health" | jq '.'
else
    echo -e "${RED}❌ Server health check failed${NC}"
fi

echo ""

# Test 2: OHIF Configuration
echo "🔍 Testing OHIF configuration..."
if curl -k -s "$SERVER_URL/api/config" > /dev/null; then
    echo -e "${GREEN}✅ OHIF configuration accessible${NC}"
    echo "Data sources configured:"
    curl -k -s "$SERVER_URL/api/config" | jq '.dataSources[].configuration.friendlyName'
else
    echo -e "${RED}❌ OHIF configuration failed${NC}"
fi

echo ""

# Test 3: Orthanc Connection
echo "🔍 Testing Orthanc connection..."
if curl -k -s "$ORTHANC_URL/system" > /dev/null; then
    echo -e "${GREEN}✅ Orthanc server accessible${NC}"
    echo "Orthanc version:"
    curl -k -s "$ORTHANC_URL/system" | jq '.Version'
else
    echo -e "${RED}❌ Orthanc connection failed${NC}"
fi

echo ""

# Test 4: DICOM-Web Endpoint (through proxy)
echo "🔍 Testing DICOM-Web endpoint through proxy..."
if curl -k -s "$SERVER_URL/dicom-web/studies" > /dev/null; then
    echo -e "${GREEN}✅ DICOM-Web proxy endpoint accessible${NC}"
    STUDY_COUNT=$(curl -k -s "$SERVER_URL/dicom-web/studies" | jq '. | length')
    echo "Studies available through proxy: $STUDY_COUNT"
else
    echo -e "${RED}❌ DICOM-Web proxy endpoint failed${NC}"
fi

echo ""

# Test 5: Orthanc Test Endpoint
echo "🔍 Testing Orthanc connectivity test endpoint..."
if curl -k -s "$SERVER_URL/api/test-orthanc" > /dev/null; then
    echo -e "${GREEN}✅ Orthanc test endpoint accessible${NC}"
    curl -k -s "$SERVER_URL/api/test-orthanc" | jq '.'
else
    echo -e "${RED}❌ Orthanc test endpoint failed${NC}"
fi

echo ""

# Test 5: Static Files
echo "🔍 Testing static file serving..."
if curl -k -s "$SERVER_URL" | grep -q "OHIF"; then
    echo -e "${GREEN}✅ Static files served correctly${NC}"
else
    echo -e "${RED}❌ Static file serving failed${NC}"
fi

echo ""
echo "🎉 Testing complete!"
