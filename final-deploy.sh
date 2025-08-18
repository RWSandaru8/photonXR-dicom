#!/bin/bash

echo "=== Final Image Display Fix Deployment ==="

# Commit all changes
echo "Committing all changes..."
git add .
git commit -m "Complete OHIF image display fix with enhanced WADO-URI and simplified config"
git push origin main

echo ""
echo "=== Deploy on Linux Server ==="
echo "Run these commands on your Linux server:"
echo ""
echo "cd /path/to/your/project"
echo "git pull origin main"
echo "pm2 stop ohif-viewer"
echo "pm2 start server.js --name ohif-viewer --watch"
echo "pm2 logs ohif-viewer"
echo ""
echo "=== Test URLs ==="
echo "OHIF Viewer: https://dentax.globalpearlventures.com:3000"
echo "Test Orthanc: https://dentax.globalpearlventures.com:3000/api/test-orthanc"
echo "Test WADO: https://dentax.globalpearlventures.com:3000/api/test-wado/{STUDY_UID}"
echo ""
echo "=== Key Fixes Applied ==="
echo "1. Enhanced WADO-URI endpoint with proper error handling"
echo "2. Simplified OHIF configuration with staticWado: true"
echo "3. Direct image endpoint for testing"
echo "4. Comprehensive logging for debugging"
echo "5. Enabled study browser to help with display sets"
