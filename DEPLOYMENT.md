# OHIF Viewer Deployment Guide

## Overview
This customized OHIF viewer is configured to run on HTTPS port 3000 and connect to an Orthanc server running on port 4000.

## Linux Server Deployment

### Prerequisites
- Node.js 18+ installed
- Yarn package manager
- SSL certificates in place at `/etc/letsencrypt/live/dentax.globalpearlventures.com/`
- Orthanc server running on `https://dentax.globalpearlventures.com:4000`

### Deployment Steps

1. **Clone and setup the project:**
```bash
git clone <your-repo-url>
cd photonXR-dicom
yarn install
```

2. **Build the OHIF viewer:**
```bash
yarn build
```

3. **Install PM2 for production process management:**
```bash
npm install -g pm2
```

4. **Start the server with PM2:**
```bash
pm2 start server.js --name "ohif-viewer"
```

5. **Configure PM2 to restart on system reboot:**
```bash
pm2 startup
pm2 save
```

### Development Commands
- `yarn dev` - Start development server
- `yarn build` - Build production version
- `yarn start:server` - Start the Node.js server

### Production Commands
- `pm2 start server.js --name "ohif-viewer"` - Start with PM2
- `pm2 restart ohif-viewer` - Restart the service
- `pm2 logs ohif-viewer` - View logs
- `pm2 stop ohif-viewer` - Stop the service

### Server Configuration

The server is configured to:
- Run on HTTPS port 3000
- Use SSL certificates from Let's Encrypt
- Proxy DICOM-Web requests to Orthanc server on port 4000
- Serve the built OHIF viewer application

### Environment Variables (Optional)
You can override the default port by setting:
```bash
export PORT=3000
```

### Firewall Configuration
Make sure port 3000 is open:
```bash
sudo ufw allow 3000
```

### Checking Server Status
- Health check: `https://dentax.globalpearlventures.com:3000/api/health`
- Main application: `https://dentax.globalpearlventures.com:3000`

### Troubleshooting

1. **SSL Certificate Issues:**
   - Ensure certificates exist at `/etc/letsencrypt/live/dentax.globalpearlventures.com/`
   - Check certificate permissions: `sudo chmod 644 /etc/letsencrypt/live/dentax.globalpearlventures.com/*`

2. **Orthanc Connection Issues:**
   - Verify Orthanc is running on port 4000
   - Check if Orthanc accepts HTTPS connections
   - Review proxy logs: `pm2 logs ohif-viewer`

3. **Port Already in Use:**
   - Check what's using port 3000: `sudo netstat -tlnp | grep :3000`
   - Kill the process or change the port

### Log Locations
- PM2 logs: `~/.pm2/logs/`
- Application logs: Check PM2 logs with `pm2 logs ohif-viewer`
