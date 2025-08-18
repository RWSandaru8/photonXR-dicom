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
HEALTH_RESPONSE=$(curl -k -s "$SERVER_URL/api/health")
if [ -n "$HEALTH_RESPONSE" ] && [[ "$HEALTH_RESPONSE" == *"ok"* ]]; then
    echo -e "${GREEN}✅ Server health check passed${NC}"
    echo "Health response: $HEALTH_RESPONSE"
else
    echo -e "${RED}❌ Server health check failed${NC}"
    echo "Health response: $HEALTH_RESPONSE"
fi

echo ""

# Test 2: OHIF Configuration
echo "🔍 Testing OHIF configuration..."
CONFIG_RESPONSE=$(curl -k -s "$SERVER_URL/api/config")
if [ -n "$CONFIG_RESPONSE" ] && [[ "$CONFIG_RESPONSE" == *"dataSources"* ]]; then
    echo -e "${GREEN}✅ OHIF configuration accessible${NC}"
    echo "Config contains dataSources: ✓"
else
    echo -e "${RED}❌ OHIF configuration failed${NC}"
    echo "Config response: $CONFIG_RESPONSE"
fi

echo ""

# Test 3: Orthanc Connection
echo "🔍 Testing Orthanc connection..."
ORTHANC_SYSTEM=$(curl -k -s "$ORTHANC_URL/system")
if [ -n "$ORTHANC_SYSTEM" ] && [[ "$ORTHANC_SYSTEM" == *"Version"* ]]; then
    echo -e "${GREEN}✅ Orthanc server accessible${NC}"
    echo "Orthanc system info: $ORTHANC_SYSTEM"
else
    echo -e "${RED}❌ Orthanc connection failed${NC}"
    echo "Orthanc response: $ORTHANC_SYSTEM"
fi

echo ""

# Test 4: DICOM-Web Endpoint (through proxy)
echo "🔍 Testing DICOM-Web endpoint through proxy..."
STUDIES_RESPONSE=$(curl -k -s "$SERVER_URL/dicom-web/studies")
if [ -n "$STUDIES_RESPONSE" ]; then
    echo -e "${GREEN}✅ DICOM-Web proxy endpoint accessible${NC}"
    if [[ "$STUDIES_RESPONSE" == "[]" ]]; then
        echo "Studies available through proxy: 0 (empty array)"
    else
        echo "Studies response: $STUDIES_RESPONSE"
    fi
else
    echo -e "${RED}❌ DICOM-Web proxy endpoint failed${NC}"
fi

echo ""

# Test 5: Orthanc Test Endpoint
echo "🔍 Testing Orthanc connectivity test endpoint..."
ORTHANC_TEST=$(curl -k -s "$SERVER_URL/api/test-orthanc")
if [ -n "$ORTHANC_TEST" ] && [[ "$ORTHANC_TEST" == *"success"* ]]; then
    echo -e "${GREEN}✅ Orthanc test endpoint accessible${NC}"
    echo "Test result: $ORTHANC_TEST"
else
    echo -e "${RED}❌ Orthanc test endpoint failed${NC}"
    echo "Test response: $ORTHANC_TEST"
fi

echo ""

# Test 6: Static Files
echo "🔍 Testing static file serving..."
VIEWER_RESPONSE=$(curl -k -s "$SERVER_URL" | head -n 10)
if [[ "$VIEWER_RESPONSE" == *"html"* ]] || [[ "$VIEWER_RESPONSE" == *"DOCTYPE"* ]]; then
    echo -e "${GREEN}✅ Static files served correctly${NC}"
    echo "HTML content detected"
else
    echo -e "${RED}❌ Static file serving failed${NC}"
    echo "Response: $VIEWER_RESPONSE"
fi

echo ""
echo "🎉 Testing complete!"
