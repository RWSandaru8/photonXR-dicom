# OHIF Network Troubleshooting Guide

## Issue: https://dentax.globalpearlventures.com:3000 not loading

### Server Status ✅
- OHIF server is running correctly
- Local connections working (127.0.0.1:3000)
- External connections working (10.1.0.4:3000)
- Orthanc server accessible

### Likely Causes:
1. **Firewall blocking port 3000**
2. **DNS not pointing to server**
3. **Cloud security group not allowing port 3000**
4. **HTTPS vs HTTP mismatch**

## Quick Fix Steps:

### 1. Make scripts executable and run diagnostics:
```bash
chmod +x diagnose-network.sh fix-network.sh
./diagnose-network.sh
```

### 2. Apply common fixes:
```bash
sudo ./fix-network.sh
```

### 3. Manual firewall fix:
```bash
# Ubuntu/Debian
sudo ufw allow 3000/tcp
sudo ufw reload

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --reload
```

### 4. Test direct IP access:
```bash
# Get your server's public IP
curl ifconfig.me

# Test direct access (replace with your IP)
curl http://YOUR_PUBLIC_IP:3000/
```

### 5. Check DNS:
```bash
nslookup dentax.globalpearlventures.com
# Should return your server's IP
```

### 6. Cloud Provider Settings:

#### AWS EC2:
- Security Group: Add inbound rule TCP 3000 from 0.0.0.0/0
- Network ACL: Ensure allows port 3000

#### Google Cloud:
```bash
gcloud compute firewall-rules create allow-ohif \
  --allow tcp:3000 \
  --source-ranges 0.0.0.0/0
```

#### Azure:
- Network Security Group: Add inbound rule for port 3000

## Current Working URLs:
- ✅ Local: http://localhost:3000
- ✅ Internal: http://10.1.0.4:3000
- ❓ Public: http://dentax.globalpearlventures.com:3000

## Test Commands:
```bash
# Check if port is open externally
telnet dentax.globalpearlventures.com 3000

# Test with curl
curl -I http://dentax.globalpearlventures.com:3000

# Check server logs
tail -f /tmp/ohif-server.log
```

## Expected Result:
Once fixed, you should be able to access:
- http://dentax.globalpearlventures.com:3000 (HTTP)
- https://dentax.globalpearlventures.com:3000 (if SSL configured)

The server is running correctly - this is purely a network/firewall configuration issue.
