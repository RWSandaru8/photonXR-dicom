# 🚀 OHIF Viewer Production Deployment Guide

## Server Deployment Steps

Since your Docker build was successful, here are the steps to deploy on your server:

### 1. Check Current Container Status

```bash
# Check if the container is running
docker ps -a

# If running, check the port mapping
docker port ohif-viewer
```

### 2. Fix Port Access Issue

The issue is likely that nginx is configured for port 3000 but should use port 80 internally. Here's how to fix it:

```bash
# Stop current containers
docker-compose down

# Rebuild with correct configuration
docker-compose up --build -d
```

### 3. Test Connectivity

```bash
# Test internal container health
docker exec ohif-viewer wget -qO- http://localhost/health

# Test external access
curl -I http://your-server-ip:3000
curl -I http://your-server-ip:3000/health
```

### 4. Enable SSL (Production)

For your domain `dentax.globalpearlventures.com`:

```bash
# 1. Ensure Let's Encrypt certificates exist
ls -la /etc/letsencrypt/live/dentax.globalpearlventures.com/

# 2. Use production docker-compose with SSL
docker-compose -f docker-compose.prod.yml up --build -d
```

### 5. Check Logs for Issues

```bash
# OHIF Viewer logs
docker logs ohif-viewer -f

# Orthanc logs
docker logs orthanc-server -f

# Nginx access logs inside container
docker exec ohif-viewer tail -f /var/log/nginx/access.log
docker exec ohif-viewer tail -f /var/log/nginx/error.log
```

### 6. Common Fixes

#### Fix 1: Nginx Configuration
```bash
# Check nginx config is correct
docker exec ohif-viewer nginx -t

# Reload nginx
docker exec ohif-viewer nginx -s reload
```

#### Fix 2: Port Binding
```bash
# Check what ports the container is actually listening on
docker exec ohif-viewer netstat -tlnp

# Should show:
# tcp  0.0.0.0:80   0.0.0.0:*   LISTEN
```

#### Fix 3: Firewall (if needed)
```bash
# Ubuntu/Debian
sudo ufw allow 3000
sudo ufw allow 3443

# CentOS/RHEL
sudo firewall-cmd --permanent --add-port=3000/tcp
sudo firewall-cmd --permanent --add-port=3443/tcp
sudo firewall-cmd --reload
```

### 7. Verify Complete Setup

Once fixed, you should be able to access:

- **HTTP**: http://your-server-ip:3000
- **HTTPS**: https://dentax.globalpearlventures.com:3443 (if SSL configured)
- **Health**: http://your-server-ip:3000/health
- **Orthanc**: http://your-server-ip:4000

### 8. Production Checklist

- [ ] OHIF accessible on port 3000
- [ ] Orthanc accessible on port 4000
- [ ] Health endpoint responding
- [ ] SSL certificates mounted (if using HTTPS)
- [ ] CORS headers working
- [ ] Can upload DICOM files to Orthanc
- [ ] DICOM files visible in OHIF

### 9. Quick Rebuild Command

If you need to rebuild everything:

```bash
# Complete rebuild
docker-compose down -v
docker system prune -f
docker-compose up --build -d

# Check status
docker-compose ps
docker-compose logs -f
```

## Troubleshooting Commands

```bash
# Container details
docker inspect ohif-viewer

# Port mappings
docker port ohif-viewer

# Process list inside container
docker exec ohif-viewer ps aux

# Network connectivity
docker exec ohif-viewer ping orthanc-server
docker exec orthanc-server ping ohif-viewer
```

## SSL Configuration (Optional)

If you want HTTPS on your domain:

1. **Verify certificates**:
```bash
sudo ls -la /etc/letsencrypt/live/dentax.globalpearlventures.com/
```

2. **Use SSL docker-compose**:
```bash
docker-compose -f docker-compose.prod.yml up --build -d
```

3. **Test HTTPS**:
```bash
curl -I https://dentax.globalpearlventures.com:3443
```

The configuration is already set up for your domain with proper SSL settings!
