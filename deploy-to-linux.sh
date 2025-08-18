#!/bin/bash

# Deploy updated OHIF server to Linux
echo "🚀 Deploying OHIF server updates..."

# Stop the current server
echo "📛 Stopping current OHIF server..."
pm2 stop ohif-viewer 2>/dev/null || echo "Server not running"

# Pull latest changes
echo "📥 Pulling latest changes from Git..."
git pull origin main

# Install dependencies (if package.json changed)
echo "📦 Installing dependencies..."
yarn install --frozen-lockfile

# Build OHIF viewer with updated configuration
echo "🔨 Building OHIF viewer..."
yarn build

# Start the server with PM2
echo "🚀 Starting OHIF server with PM2..."
pm2 start server.js --name ohif-viewer --log-file /var/log/ohif-viewer.log

# Show server status
echo "📊 Server status:"
pm2 status

# Test endpoints
echo "🧪 Testing endpoints..."
sleep 5

echo "Testing health endpoint..."
curl -k -s https://dentax.globalpearlventures.com:3000/api/health | jq . || echo "Health check failed"

echo "Testing Orthanc connectivity..."
curl -k -s https://dentax.globalpearlventures.com:3000/api/test-orthanc | jq . || echo "Orthanc test failed"

echo "Testing enhanced debug endpoint..."
# Get first study UID for testing
STUDY_UID=$(curl -k -s https://dentax.globalpearlventures.com:4000/studies | jq -r '.[0]' | xargs -I {} curl -k -s https://dentax.globalpearlventures.com:4000/studies/{} | jq -r '.MainDicomTags.StudyInstanceUID')
if [ "$STUDY_UID" != "null" ] && [ -n "$STUDY_UID" ]; then
    echo "Testing with study UID: $STUDY_UID"
    curl -k -s "https://dentax.globalpearlventures.com:3000/api/debug-orthanc-study/$STUDY_UID" | jq .ohifUrl || echo "Enhanced debug test failed"
fi

echo "✅ Deployment completed!"
echo "🌐 OHIF Viewer: https://dentax.globalpearlventures.com:3000"
echo "📊 Health Check: https://dentax.globalpearlventures.com:3000/api/health"
echo "📋 Logs: pm2 logs ohif-viewer"
