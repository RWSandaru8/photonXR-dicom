#!/bin/bash

# OHIF Viewer Deployment Script for Linux Server
# Run this script on your Linux server to deploy the OHIF viewer

set -e

echo "🚀 Starting OHIF Viewer deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if running as root (needed for SSL certificates)
if [[ $EUID -eq 0 ]]; then
   echo -e "${YELLOW}Warning: Running as root. Consider using a non-root user for security.${NC}"
fi

# Check Node.js version
echo "📋 Checking Node.js version..."
if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js 18+${NC}"
    exit 1
fi

NODE_VERSION=$(node -v | cut -d'v' -f2)
echo "✅ Node.js version: $NODE_VERSION"

# Check Yarn
echo "📋 Checking Yarn..."
if ! command -v yarn &> /dev/null; then
    echo -e "${YELLOW}⚠️  Yarn not found. Installing Yarn...${NC}"
    npm install -g yarn
fi

YARN_VERSION=$(yarn -v)
echo "✅ Yarn version: $YARN_VERSION"

# Install dependencies
echo "📦 Installing dependencies..."
yarn install --production=false

# Build the project
echo "🔨 Building OHIF viewer with production config..."
echo "   Setting APP_CONFIG=config/production.js"
echo "   Setting NODE_ENV=production"
export APP_CONFIG=config/production.js
export NODE_ENV=production

# Use the main build script which now has correct env vars
yarn run build

# Verify the configuration
echo "🔍 Verifying build used correct configuration..."
if [ -f "platform/app/dist/app-config.js" ]; then
    if grep -q "d14fa38qiwhyfd.cloudfront.net" platform/app/dist/app-config.js; then
        echo "❌ ERROR: Build still contains CloudFront URLs!"
        echo "   Check the build configuration."
        exit 1
    else
        echo "✅ Build uses correct configuration (no CloudFront URLs)"
    fi
else
    echo "❌ app-config.js not found in build"
    exit 1
fi

# Check SSL certificates
echo "🔒 Checking SSL certificates..."
SSL_PATH="/etc/letsencrypt/live/dentax.globalpearlventures.com"
if [ ! -f "$SSL_PATH/privkey.pem" ] || [ ! -f "$SSL_PATH/fullchain.pem" ]; then
    echo -e "${RED}❌ SSL certificates not found at $SSL_PATH${NC}"
    echo "Please ensure Let's Encrypt certificates are installed."
    exit 1
fi
echo "✅ SSL certificates found"

# Create logs directory
mkdir -p logs

# Install PM2 globally if not installed
if ! command -v pm2 &> /dev/null; then
    echo "📦 Installing PM2..."
    npm install -g pm2
fi

# Stop existing instance if running
echo "🛑 Stopping existing OHIF viewer instance..."
pm2 stop ohif-viewer 2>/dev/null || true
pm2 delete ohif-viewer 2>/dev/null || true

# Start the application
echo "🚀 Starting OHIF viewer..."
pm2 start ecosystem.config.json

# Setup PM2 startup script
echo "⚙️  Setting up PM2 startup script..."
pm2 startup || echo "PM2 startup script may need manual configuration"
pm2 save

# Show status
echo "📊 Application status:"
pm2 status

echo ""
echo -e "${GREEN}✅ OHIF Viewer deployed successfully!${NC}"
echo ""
echo "🌐 Application URL: https://dentax.globalpearlventures.com:3000"
echo "🔍 Health check: https://dentax.globalpearlventures.com:3000/api/health"
echo "📊 View logs: pm2 logs ohif-viewer"
echo "🔄 Restart: pm2 restart ohif-viewer"
echo ""
echo "🎉 Deployment complete!"
