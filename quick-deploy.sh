#!/bin/bash

echo "🚀 Quick deployment of server.js fixes..."

# Stop current server
echo "📛 Stopping OHIF server..."
pm2 stop ohif-viewer 2>/dev/null || echo "Server not running"

# Pull latest changes
echo "📥 Pulling latest changes..."
git pull origin main

# Start server immediately (no rebuild needed since we're only changing server.js)
echo "🚀 Starting updated OHIF server..."
pm2 start server.js --name ohif-viewer --log-file /var/log/ohif-viewer.log

# Show status
echo "📊 Server status:"
pm2 status

# Quick test
echo "🧪 Quick connectivity test..."
sleep 3
curl -k -s https://dentax.globalpearlventures.com:3000/api/health | jq .status || echo "Health check failed"

echo "✅ Quick deployment completed!"
echo "🌐 Test OHIF: https://dentax.globalpearlventures.com:3000"
echo "📋 Watch logs: pm2 logs ohif-viewer"
