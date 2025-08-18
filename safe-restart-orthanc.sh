#!/bin/bash

echo "🔧 Safely updating Orthanc configuration..."

# Backup existing configuration
echo "📋 Creating backup..."
sudo cp /var/lib/orthanc/config/orthanc.json /var/lib/orthanc/config/orthanc.json.backup.$(date +%Y%m%d_%H%M%S)

# Instead of replacing the entire config, just restart with the existing one first
echo "🔄 Restarting Orthanc with current configuration..."
cd /var/lib/orthanc
sudo docker-compose down
sudo docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 15

# Test if Orthanc is working
echo "🧪 Testing Orthanc connectivity..."
if curl -k -s https://dentax.globalpearlventures.com:4000/system | grep -q "Name"; then
    echo "✅ Orthanc is running with current configuration"

    # Test DICOM-Web endpoints
    echo "Testing DICOM-Web endpoints..."
    curl -k -s -H "Accept: application/dicom+json" https://dentax.globalpearlventures.com:4000/dicom-web/studies | head -20

    echo "Testing WADO endpoint..."
    curl -k -s -I https://dentax.globalpearlventures.com:4000/wado

else
    echo "❌ Orthanc failed to start. Checking logs..."
    sudo docker-compose logs orthanc | tail -20

    echo "🔄 Trying to restore from backup..."
    # Find the most recent backup
    LATEST_BACKUP=$(ls -t /var/lib/orthanc/config/orthanc.json.backup.* 2>/dev/null | head -1)
    if [ -n "$LATEST_BACKUP" ]; then
        echo "Restoring from: $LATEST_BACKUP"
        sudo cp "$LATEST_BACKUP" /var/lib/orthanc/config/orthanc.json
        sudo docker-compose down
        sudo docker-compose up -d
        sleep 10

        if curl -k -s https://dentax.globalpearlventures.com:4000/system | grep -q "Name"; then
            echo "✅ Orthanc restored successfully"
        else
            echo "❌ Failed to restore Orthanc"
        fi
    else
        echo "❌ No backup found"
    fi
fi

# Check container status
echo "📊 Container status:"
sudo docker-compose ps

echo ""
echo "📋 Next steps:"
echo "1. If Orthanc is running, test OHIF: https://dentax.globalpearlventures.com:3000"
echo "2. Check logs if needed: sudo docker-compose logs orthanc"
echo "3. Deploy OHIF server: ./deploy-to-linux.sh"
