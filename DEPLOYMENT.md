# OHIF Viewer Deployment Guide

## Overview
This customized OHIF viewer runs on HTTPS port 3000 and connects to Orthanc server on port 4000.

## Orthanc Configuration
The viewer is configured to use these DICOM-Web endpoints:
- **QIDO Root**: `https://dentax.globalpearlventures.com:4000/dicom-web`
- **WADO Root**: `https://dentax.globalpearlventures.com:4000/dicom-web`
- **WADO URI**: `https://dentax.globalpearlventures.com:4000/wado`

## Quick Deployment

1. **Deploy to Linux server:**
```bash
git pull
chmod +x deploy.sh
./deploy.sh
```

2. **Test deployment:**
```bash
chmod +x test.sh
./test.sh
```

## Manual Deployment Steps

```bash
yarn install
yarn build
pm2 start ecosystem.config.json
```

## Key URLs
- **Application**: `https://dentax.globalpearlventures.com:3000`
- **Health Check**: `https://dentax.globalpearlventures.com:3000/api/health`
- **Configuration**: `https://dentax.globalpearlventures.com:3000/api/config`

## Management Commands
- Start: `pm2 start ecosystem.config.json`
- Stop: `pm2 stop ohif-viewer`
- Restart: `pm2 restart ohif-viewer`
- Logs: `pm2 logs ohif-viewer`
- Status: `pm2 status`

## Prerequisites
- Node.js 18+, Yarn, PM2
- SSL certificates at `/etc/letsencrypt/live/dentax.globalpearlventures.com/`
- Orthanc server running on port 4000
