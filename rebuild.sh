#!/bin/bash

# Quick rebuild script to fix OHIF configuration
# Run this on your Linux server after making config changes

echo "🔄 Rebuilding OHIF with correct configuration..."

# Stop the current server
echo "🛑 Stopping current OHIF server..."
pm2 stop ohif-viewer 2>/dev/null || true

# Clean previous build
echo "🧹 Cleaning previous build..."
yarn clean

# Rebuild with production config
echo "🔨 Building with production configuration..."
export APP_CONFIG=config/production.js
export NODE_ENV=production
yarn build:production

# Restart the server
echo "🚀 Restarting OHIF server..."
pm2 start server.js --name "ohif-viewer"

# Show status
echo "📊 Current status:"
pm2 status ohif-viewer

echo ""
echo "✅ Rebuild complete!"
echo "🌐 Test your viewer at: https://dentax.globalpearlventures.com:3000"
echo "🔍 Debug endpoint: https://dentax.globalpearlventures.com:3000/api/debug"
echo "📋 Check logs: pm2 logs ohif-viewer"
