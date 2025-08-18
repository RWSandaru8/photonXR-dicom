#!/bin/bash

# OHIF Viewer Deployment Script for Linux Server
set -e

echo "🚀 Starting OHIF Viewer deployment..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check Node.js and Yarn
echo "📋 Checking prerequisites..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js not found. Please install Node.js 18+${NC}"
    exit 1
fi

if ! command -v yarn &> /dev/null; then
    echo "📦 Installing Yarn..."
    npm install -g yarn
fi

echo "✅ Node.js $(node -v) and Yarn $(yarn -v) ready"

# Check SSL certificates
SSL_PATH="/etc/letsencrypt/live/dentax.globalpearlventures.com"
if [ ! -f "$SSL_PATH/privkey.pem" ] || [ ! -f "$SSL_PATH/fullchain.pem" ]; then
    echo -e "${RED}❌ SSL certificates not found at $SSL_PATH${NC}"
    exit 1
fi
echo "✅ SSL certificates found"

# Install dependencies and build
echo "📦 Installing dependencies..."
yarn install

echo "🔨 Building OHIF viewer..."
yarn build

# Setup PM2 and deploy
if ! command -v pm2 &> /dev/null; then
    npm install -g pm2
fi

mkdir -p logs

# Stop and restart application
pm2 stop ohif-viewer 2>/dev/null || true
pm2 delete ohif-viewer 2>/dev/null || true
pm2 start ecosystem.config.json
pm2 save

echo ""
echo -e "${GREEN}✅ OHIF Viewer deployed successfully!${NC}"
echo "🌐 Application: https://dentax.globalpearlventures.com:3000"
echo "🔍 Health check: https://dentax.globalpearlventures.com:3000/api/health"
echo "📊 Status: pm2 status"
echo "🎉 Deployment complete!"
