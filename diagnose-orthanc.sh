#!/bin/bash

echo "🔍 Diagnosing Orthanc startup issues..."

# Check if containers are running
echo "📊 Container status:"
cd /var/lib/orthanc
sudo docker-compose ps

echo ""
echo "📋 Orthanc container logs (last 30 lines):"
sudo docker-compose logs --tail=30 orthanc

echo ""
echo "📋 Nginx container logs (last 10 lines):"
sudo docker-compose logs --tail=10 nginx

echo ""
echo "🔍 Checking Orthanc configuration file syntax..."
if command -v jq &> /dev/null; then
    if jq empty /var/lib/orthanc/config/orthanc.json 2>/dev/null; then
        echo "✅ JSON syntax is valid"
    else
        echo "❌ JSON syntax error in orthanc.json:"
        jq empty /var/lib/orthanc/config/orthanc.json
    fi
else
    echo "jq not installed, cannot validate JSON syntax"
fi

echo ""
echo "📁 Configuration file location and permissions:"
ls -la /var/lib/orthanc/config/orthanc.json

echo ""
echo "📁 Available backup files:"
ls -la /var/lib/orthanc/config/orthanc.json.backup.* 2>/dev/null || echo "No backup files found"

echo ""
echo "🔄 Attempting to restart containers..."
sudo docker-compose down
sleep 5
sudo docker-compose up -d

echo ""
echo "⏳ Waiting 15 seconds for startup..."
sleep 15

echo ""
echo "🧪 Testing connectivity..."
if curl -k -s https://dentax.globalpearlventures.com:4000/system | grep -q "Name"; then
    echo "✅ Orthanc is accessible"
    echo "System info:"
    curl -k -s https://dentax.globalpearlventures.com:4000/system | jq .Name,.Version,.ApiVersion 2>/dev/null || curl -k -s https://dentax.globalpearlventures.com:4000/system
else
    echo "❌ Orthanc is not accessible"
    echo "Checking if port 4000 is listening..."
    ss -tlnp | grep :4000 || echo "Port 4000 not listening"
fi

echo ""
echo "📋 Docker container details:"
sudo docker inspect orthanc-server | jq '.[0].State' 2>/dev/null || sudo docker inspect orthanc-server | grep -A 10 "State"
