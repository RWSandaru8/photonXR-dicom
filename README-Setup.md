# OHIF Viewer with Orthanc Server - Setup Guide

This guide explains how to build and run the OHIF DICOM Viewer connected to an Orthanc server.

## Architecture Overview

- **OHIF Viewer**: Web-based DICOM viewer running on port 3000
- **Orthanc Server**: DICOM server with DICOMWeb API running on port 4000 (8042 internally)
- **Communication**: OHIF connects to Orthanc via DICOMWeb REST API with CORS enabled

## Files Created/Modified

1. `config/orthanc-config.js` - OHIF configuration for Orthanc connection
2. `docker-compose.yml` - Complete Docker Compose setup
3. `orthanc-config/orthanc.json` - Orthanc server configuration
4. `build-and-run.sh` - Linux/Mac build script
5. `build-and-run.ps1` - Windows PowerShell build script

## Prerequisites

- Docker and Docker Compose installed
- Ports 3000 and 4000 available
- At least 2GB RAM available for Docker

## Quick Start (Recommended)

### Using Docker Compose (Recommended)

```powershell
# Clone and navigate to the project directory
cd d:\Github\photonXR-dicom

# Start both services with Docker Compose
docker-compose up -d

# Check logs
docker-compose logs -f
```

This will start:
- OHIF Viewer on http://localhost:3000
- Orthanc Server on http://localhost:4000

### Using PowerShell Script

```powershell
# Navigate to project directory
cd d:\Github\photonXR-dicom

# Run the PowerShell script
.\build-and-run.ps1
```

## Manual Build Process

### Step 1: Build OHIF Viewer

```powershell
docker build -t ohif-viewer:latest --build-arg APP_CONFIG=config/orthanc-config.js .
```

### Step 2: Run Orthanc Server

```powershell
docker run -d `
  --name orthanc-server `
  -p 4000:8042 `
  -p 4242:4242 `
  -v orthanc-db:/var/lib/orthanc/db `
  -v orthanc-storage:/var/lib/orthanc/storage `
  -v "${PWD}/orthanc-config:/etc/orthanc/:ro" `
  -e ORTHANC__DICOM_WEB__ENABLE=true `
  -e ORTHANC__HTTP_CORS__ENABLED=true `
  orthancteam/orthanc:latest
```

### Step 3: Run OHIF Viewer

```powershell
docker run -d `
  --name ohif-viewer `
  -p 3000:80 `
  --link orthanc-server:orthanc `
  ohif-viewer:latest
```

## Access Points

- **OHIF Viewer**: http://localhost:3000
- **Orthanc Web UI**: http://localhost:4000
- **Orthanc DICOMWeb API**: http://localhost:4000/dicom-web/

## Configuration Details

### OHIF Configuration (`config/orthanc-config.js`)

- **Primary Data Source**: Orthanc server
- **DICOMWeb Endpoints**: All pointing to `localhost:4000/dicom-web`
- **CORS**: Configured to work with Orthanc
- **Features Enabled**: WADO-RS, QIDO-RS, STOW-RS

### Orthanc Configuration (`orthanc-config/orthanc.json`)

- **DICOMWeb Plugin**: Enabled with full API support
- **CORS**: Enabled for cross-origin requests
- **Authentication**: Disabled for development
- **Storage**: Persistent volumes for data retention

## Uploading DICOM Files

### Method 1: Orthanc Web Interface
1. Open http://localhost:4000
2. Click "Upload" in the top menu
3. Drag and drop DICOM files or folders

### Method 2: REST API
```powershell
# Upload a DICOM file via REST API
curl -X POST http://localhost:4000/instances --data-binary @your-dicom-file.dcm
```

### Method 3: DICOM C-STORE
```powershell
# Using DICOM tools to send to Orthanc
storescu -aec ORTHANC localhost 4242 your-dicom-file.dcm
```

## Verification Steps

1. **Check Containers**:
   ```powershell
   docker ps
   ```

2. **Check Orthanc**:
   - Open http://localhost:4000
   - Should show Orthanc Explorer interface

3. **Check OHIF**:
   - Open http://localhost:3000
   - Should show OHIF Study List (empty if no studies)

4. **Check DICOMWeb API**:
   ```powershell
   curl http://localhost:4000/dicom-web/studies
   ```

## Troubleshooting

### Common Issues

1. **CORS Errors**:
   - Ensure Orthanc has CORS enabled in configuration
   - Check browser developer console for CORS errors

2. **Connection Refused**:
   - Verify Orthanc is running on port 4000
   - Check if ports are available: `netstat -an | findstr "3000\|4000"`

3. **Empty Study List**:
   - Upload DICOM files to Orthanc first
   - Verify API endpoint: http://localhost:4000/dicom-web/studies

4. **Build Failures**:
   - Ensure Docker has enough memory (>2GB)
   - Check Docker logs: `docker logs ohif-viewer`

### Useful Commands

```powershell
# Stop and remove containers
docker-compose down

# Rebuild and restart
docker-compose up --build -d

# View logs
docker logs ohif-viewer
docker logs orthanc-server

# Clean up everything
docker-compose down -v
docker rmi ohif-viewer:latest
```

## Production Considerations

1. **Security**:
   - Enable Orthanc authentication
   - Use HTTPS
   - Restrict CORS origins

2. **Performance**:
   - Increase Orthanc cache sizes
   - Use faster storage for Orthanc data
   - Configure load balancing

3. **Backup**:
   - Backup Orthanc database and storage volumes
   - Consider database replication

## Network Configuration

If connecting to an external Orthanc server:

1. **Update OHIF Config**: Modify `config/orthanc-config.js`:
   ```javascript
   wadoUriRoot: 'http://your-orthanc-server:4000/dicom-web',
   qidoRoot: 'http://your-orthanc-server:4000/dicom-web',
   wadoRoot: 'http://your-orthanc-server:4000/dicom-web',
   ```

2. **Ensure Network Connectivity**: Test connection:
   ```powershell
   curl http://your-orthanc-server:4000/dicom-web/studies
   ```

## Support

- **OHIF Documentation**: https://docs.ohif.org/
- **Orthanc Documentation**: https://book.orthanc-server.com/
- **Docker Documentation**: https://docs.docker.com/
