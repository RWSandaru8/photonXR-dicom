#!/bin/bash

echo "🔧 Updating Orthanc and Nginx configurations for OHIF compatibility..."

# Backup existing configurations
echo "📋 Creating backups..."
sudo cp /var/lib/orthanc/config/orthanc.json /var/lib/orthanc/config/orthanc.json.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /var/lib/orthanc/nginx/default.conf /var/lib/orthanc/nginx/default.conf.backup.$(date +%Y%m%d_%H%M%S)

# Download updated configurations
echo "📥 Downloading updated configurations..."
curl -o orthanc-config-updated.json https://raw.githubusercontent.com/RWSandaru8/photonXR-dicom/main/orthanc-config-updated.json
curl -o nginx-config-updated.conf https://raw.githubusercontent.com/RWSandaru8/photonXR-dicom/main/nginx-config-updated.conf

# Update Orthanc configuration
echo "🔄 Updating Orthanc configuration..."
sudo cp orthanc-config-updated.json /var/lib/orthanc/config/orthanc.json

# Update Nginx configuration  
echo "🔄 Updating Nginx configuration..."
sudo cp nginx-config-updated.conf /var/lib/orthanc/nginx/default.conf

# Restart Orthanc and Nginx containers
echo "🔄 Restarting Orthanc services..."
cd /var/lib/orthanc
sudo docker-compose down
sudo docker-compose up -d

# Wait for services to start
echo "⏳ Waiting for services to start..."
sleep 10

# Test Orthanc connectivity
echo "🧪 Testing Orthanc connectivity..."
echo "Testing system endpoint..."
curl -k -s https://dentax.globalpearlventures.com:4000/system | jq .Name || echo "❌ System test failed"

echo "Testing DICOM-Web studies endpoint..."
curl -k -s -H "Accept: application/dicom+json" https://dentax.globalpearlventures.com:4000/dicom-web/studies | jq . || echo "❌ DICOM-Web test failed"

echo "Testing WADO endpoint..."
curl -k -s -I https://dentax.globalpearlventures.com:4000/wado || echo "❌ WADO test failed"

# Check container status
echo "📊 Container status:"
sudo docker-compose ps

echo "✅ Configuration update completed!"
echo "🔧 Key changes made:"
echo "  - Enhanced DICOM-Web configuration with metadata options"
echo "  - Separate WADO-URI location block in Nginx"
echo "  - Improved CORS headers for OHIF compatibility"
echo "  - Better proxy settings for large DICOM files"

echo ""
echo "📋 Next steps:"
echo "1. Test OHIF viewer: https://dentax.globalpearlventures.com:3000"
echo "2. Check logs: sudo docker-compose logs -f"
echo "3. If issues persist, check: sudo docker-compose logs orthanc"

# Clean up downloaded files
rm -f orthanc-config-updated.json nginx-config-updated.conf
