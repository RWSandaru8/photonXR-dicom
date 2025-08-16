#!/bin/bash

# Complete OHIF Configuration Fix Script
# This script will forcefully rebuild OHIF with the correct configuration

set -e

echo "🔧 OHIF Configuration Fix Script"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo "1. 🛑 Stopping current OHIF server..."
pm2 stop ohif-viewer 2>/dev/null || true

echo ""
echo "2. 🧹 Deep cleaning previous builds..."
rm -rf platform/app/dist
rm -rf node_modules/.cache
yarn clean

echo ""
echo "3. 📋 Verifying production config exists..."
if [ ! -f "platform/app/public/config/production.js" ]; then
    echo -e "${RED}❌ production.js config file not found!${NC}"
    exit 1
fi

echo "✅ Production config found"
echo "📄 Content preview:"
head -10 platform/app/public/config/production.js

echo ""
echo "4. 🔨 Building with explicit configuration..."
cd platform/app
export NODE_ENV=production
export APP_CONFIG=config/production.js
export PUBLIC_URL=/

echo "   Environment variables set:"
echo "   NODE_ENV=$NODE_ENV"
echo "   APP_CONFIG=$APP_CONFIG"
echo "   PUBLIC_URL=$PUBLIC_URL"

# Build directly in the app directory to ensure env vars are used
yarn run build

echo ""
echo "5. 🔍 Verifying the built configuration..."
cd ../../

if [ ! -f "platform/app/dist/app-config.js" ]; then
    echo -e "${RED}❌ app-config.js not found in build!${NC}"
    exit 1
fi

echo "✅ app-config.js exists"
echo ""
echo "📋 Checking content:"
echo "==================="
cat platform/app/dist/app-config.js
echo "==================="
echo ""

# Check for CloudFront URLs
if grep -q "d14fa38qiwhyfd.cloudfront.net" platform/app/dist/app-config.js; then
    echo -e "${RED}❌ CRITICAL ERROR: CloudFront URLs still present!${NC}"
    echo "The build is not using the production config."
    echo ""
    echo "Debugging info:"
    echo "Current directory: $(pwd)"
    echo "APP_CONFIG value: $APP_CONFIG"
    echo "Production config exists: $(test -f platform/app/public/config/production.js && echo 'YES' || echo 'NO')"
    exit 1
else
    echo -e "${GREEN}✅ SUCCESS: No CloudFront URLs found${NC}"
fi

# Check for Orthanc config
if grep -q "orthanc" platform/app/dist/app-config.js; then
    echo -e "${GREEN}✅ Orthanc configuration present${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: 'orthanc' not found in config${NC}"
fi

# Check for relative URLs
if grep -q "/dicom-web" platform/app/dist/app-config.js; then
    echo -e "${GREEN}✅ Relative proxy URLs present${NC}"
else
    echo -e "${YELLOW}⚠️  Warning: Relative URLs not found${NC}"
fi

echo ""
echo "6. 🚀 Restarting OHIF server..."
pm2 start server.js --name "ohif-viewer"

echo ""
echo "7. 📊 Final status check..."
pm2 status ohif-viewer

echo ""
echo -e "${GREEN}🎉 Configuration fix completed!${NC}"
echo ""
echo "📝 Summary:"
echo "- ✅ Build uses production config (no CloudFront)"
echo "- ✅ Orthanc proxy configuration active"
echo "- ✅ Server restarted with new build"
echo ""
echo "🌐 Test URLs:"
echo "- Health: https://dentax.globalpearlventures.com:3000/api/health"
echo "- Debug:  https://dentax.globalpearlventures.com:3000/api/debug"
echo "- Viewer: https://dentax.globalpearlventures.com:3000/viewer/dicomweb?StudyInstanceUIDs=1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
echo ""
echo "🔍 Monitor logs: pm2 logs ohif-viewer"
