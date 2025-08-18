#!/bin/bash

echo "=== Deploying Display Set Fixes ==="

# Check if we're on a Linux server
if [[ "$OSTYPE" != "linux-gnu"* ]]; then
    echo "This script should be run on the Linux server"
    echo "Please copy the updated files to the server first"
    exit 1
fi

# Stop the current server
echo "Stopping OHIF server..."
pm2 stop ohif-viewer 2>/dev/null || echo "Server not running"

# Backup current server.js
if [ -f "server.js" ]; then
    cp server.js server.js.backup.$(date +%Y%m%d_%H%M%S)
    echo "Backed up current server.js"
fi

# Start the server with enhanced debugging
echo "Starting OHIF server with display set fixes..."
pm2 start server.js --name "ohif-viewer" --watch --ignore-watch="node_modules" --log-date-format="YYYY-MM-DD HH:mm:ss Z"

# Show status
echo "Server status:"
pm2 status

echo ""
echo "=== Deployment Complete ==="
echo "Monitor logs with: pm2 logs ohif-viewer"
echo "Test the viewer at: https://dentax.globalpearlventures.com:3000"
echo ""
echo "Key fixes applied:"
echo "1. Enhanced metadata endpoints with required DICOM tags"
echo "2. Proper display set configuration with hanging protocols"
echo "3. Better instance data formatting for OHIF compatibility"
echo "4. Detailed debugging for tracking data flow"
