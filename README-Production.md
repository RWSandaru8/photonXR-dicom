# 🚀 OHIF + Orthanc Production Deployment

This directory contains a production-ready OHIF DICOM viewer with Orthanc server integration.

## 📁 Project Structure

```
├── Dockerfile                    # Production-optimized OHIF build
├── docker-compose.yml           # Standard deployment
├── docker-compose.prod.yml      # Production deployment with SSL
├── deploy-ohif.sh              # Linux/Mac deployment script
├── deploy-ohif.ps1             # Windows PowerShell deployment script
├── config/                     # OHIF configuration
│   └── orthanc-config.js
├── orthanc-config/             # Orthanc server configuration
│   └── orthanc.json
└── platform/app/public/config/ # Build-time config location
```

## 🚀 Quick Deployment

### Linux/Mac
```bash
# Make script executable
chmod +x deploy-ohif.sh

# Full deployment (backup + build + start)
./deploy-ohif.sh full

# Or step by step
./deploy-ohif.sh build
./deploy-ohif.sh start
```

### Windows PowerShell
```powershell
# Full deployment (backup + build + start)
.\deploy-ohif.ps1 full

# Or step by step
.\deploy-ohif.ps1 build
.\deploy-ohif.ps1 start
```

## 🔧 Available Commands

| Command | Description |
|---------|-------------|
| `build` | Build Docker images |
| `start` | Start services |
| `stop` | Stop services |
| `restart` | Restart services |
| `backup` | Backup Orthanc data and config |
| `restore` | Restore from backup |
| `logs` | Show service logs |
| `status` | Show service status and resource usage |
| `health` | Check service health |
| `clean` | Clean up everything (destructive!) |
| `full` | Complete deployment |

## 🌐 Access Points

After successful deployment:

- **OHIF Viewer**: http://your-server:3000
- **Orthanc Web UI**: http://your-server:4000
- **Orthanc API**: http://your-server:4000/dicom-web
- **DICOM C-STORE**: your-server:4242

## 🔒 SSL Configuration

For HTTPS on your domain `dentax.globalpearlventures.com`:

1. Ensure Let's Encrypt certificates exist:
   ```bash
   ls -la /etc/letsencrypt/live/dentax.globalpearlventures.com/
   ```

2. Enable SSL mode:
   ```bash
   export USE_SSL=true
   ./deploy-ohif.sh start
   ```

3. Access via HTTPS:
   - https://dentax.globalpearlventures.com:3443

## 💾 Backup & Restore

### Automatic Backup
```bash
# Create backup with timestamp
./deploy-ohif.sh backup

# Backups are stored in ./backups/ directory
```

### Restore from Backup
```bash
# List available backups
ls -la backups/

# Restore from specific backup
./deploy-ohif.sh restore 20240815_143000
```

## 📊 Monitoring

### Check Service Status
```bash
# Overall status
./deploy-ohif.sh status

# Health check
./deploy-ohif.sh health

# View logs
./deploy-ohif.sh logs
./deploy-ohif.sh logs ohif-viewer
./deploy-ohif.sh logs orthanc-server
```

### Resource Usage
The deployment script shows:
- Container status
- Resource usage (CPU/Memory)
- Volume usage
- Network connectivity

## 🔧 Production Features

### OHIF Viewer
- ✅ Multi-stage Docker build
- ✅ Nginx with gzip compression
- ✅ Health checks
- ✅ CORS configured for Orthanc
- ✅ Production-optimized React build
- ✅ SSL/TLS support
- ✅ Static asset caching

### Orthanc Server
- ✅ DICOMWeb API enabled
- ✅ CORS configured
- ✅ Persistent storage
- ✅ Health checks
- ✅ Performance optimized
- ✅ Backup/restore support

### Infrastructure
- ✅ Docker Compose orchestration
- ✅ Automated backup system
- ✅ Service dependency management
- ✅ Health monitoring
- ✅ Resource monitoring
- ✅ Log aggregation

## 🐛 Troubleshooting

### Port 3000 Not Accessible
```bash
# Check if container is running
docker-compose ps

# Check port mapping
docker port ohif-viewer

# Check nginx status
docker exec ohif-viewer nginx -t
```

### Orthanc Connection Issues
```bash
# Check Orthanc health
curl http://localhost:4000/system

# Check CORS headers
curl -H "Origin: http://localhost:3000" -I http://localhost:4000/dicom-web/studies
```

### Build Issues
```bash
# Clean rebuild
./deploy-ohif.sh clean
./deploy-ohif.sh build
```

## 📋 System Requirements

- Docker 20.10+
- Docker Compose 2.0+
- 4GB RAM minimum
- 10GB disk space
- Ports 3000, 3443, 4000, 4242 available

## 🔄 Updates

To update the deployment:

1. Pull latest changes
2. Run backup
3. Rebuild and restart

```bash
git pull
./deploy-ohif.sh backup
./deploy-ohif.sh restart
```

## 📞 Support

For issues:
1. Check logs: `./deploy-ohif.sh logs`
2. Check health: `./deploy-ohif.sh health`
3. Check status: `./deploy-ohif.sh status`
4. Review troubleshooting section above
