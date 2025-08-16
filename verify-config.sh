#!/bin/bash

# Script to verify which configuration is being used in the built application

echo "🔍 Checking OHIF Configuration..."
echo ""

# Check if the built app exists
if [ ! -d "platform/app/dist" ]; then
    echo "❌ Build directory not found. Run './rebuild.sh' first."
    exit 1
fi

# Check app-config.js
if [ -f "platform/app/dist/app-config.js" ]; then
    echo "✅ app-config.js found in build"
    echo ""
    echo "📋 Configuration content:"
    echo "========================"
    cat platform/app/dist/app-config.js
    echo ""
    echo "========================"
    echo ""
    
    # Check for CloudFront URLs (should NOT be present)
    if grep -q "d14fa38qiwhyfd.cloudfront.net" platform/app/dist/app-config.js; then
        echo "❌ ERROR: CloudFront URLs found in config!"
        echo "   This means the default config is being used instead of production config."
        echo "   Run './rebuild.sh' to fix this."
    else
        echo "✅ No CloudFront URLs found - using correct configuration"
    fi
    
    # Check for our Orthanc configuration
    if grep -q "orthanc" platform/app/dist/app-config.js; then
        echo "✅ Orthanc configuration found"
    else
        echo "❌ Orthanc configuration NOT found"
    fi
    
    # Check for relative URLs (should be present)
    if grep -q "/dicom-web" platform/app/dist/app-config.js; then
        echo "✅ Relative proxy URLs found"
    else
        echo "❌ Relative proxy URLs NOT found"
    fi
    
else
    echo "❌ app-config.js NOT found in build directory"
fi

echo ""
echo "🌐 If all checks pass, your viewer should connect to Orthanc instead of CloudFront"
