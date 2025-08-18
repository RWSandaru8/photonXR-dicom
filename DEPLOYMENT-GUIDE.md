# Complete OHIF-Orthanc Fix Deployment Guide

## Step 1: Commit and Push All Changes

From your Windows machine:

```bash
git add .
git commit -m "Fix Orthanc DICOM-Web compatibility with updated configurations"
git push origin main
```

## Step 2: Update Orthanc and Nginx Configurations

On your Linux server, run these commands:

```bash
# Navigate to the project directory
cd /home/gpvadmin/photonXR-dicom

# Pull the latest changes (including new config files)
git pull origin main

# Make the update script executable and run it
chmod +x update-orthanc-config.sh
./update-orthanc-config.sh
```

This script will:
- ✅ Backup your existing configurations
- ✅ Update Orthanc with enhanced DICOM-Web settings
- ✅ Update Nginx with separate DICOM-Web and WADO-URI handling
- ✅ Restart the Orthanc containers
- ✅ Test the connectivity

## Step 3: Deploy Updated OHIF Server

After the Orthanc configuration is updated:

```bash
# Deploy the updated OHIF server
chmod +x deploy-to-linux.sh
./deploy-to-linux.sh
```

## Step 4: Test the Complete Setup

```bash
# Run comprehensive tests
./test-linux-endpoints.sh

# Test the enhanced debug endpoint
STUDY_UID="1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
curl -k -s "https://dentax.globalpearlventures.com:3000/api/debug-orthanc-study/$STUDY_UID" | jq .
```

## Step 5: Test OHIF Viewer

Open your browser and navigate to:
```
https://dentax.globalpearlventures.com:3000/viewer/dicomweb?StudyInstanceUIDs=1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6
```

## Key Configuration Changes Made:

### 🔧 Orthanc Configuration Updates:
1. **Enhanced DICOM-Web settings**: Added StudiesMetadata and SeriesMetadata configurations
2. **Explicit WADO configuration**: Enabled dedicated WADO support
3. **Better metadata handling**: Configured to include instance tags

### 🔧 Nginx Configuration Updates:
1. **Separate DICOM-Web location**: `/dicom-web/` with specific proxy settings
2. **Dedicated WADO-URI location**: `/wado` with binary file handling
3. **Enhanced CORS headers**: Better support for OHIF requests
4. **Improved proxy settings**: Better handling of large DICOM files

### 🔧 OHIF Server Updates:
1. **Smart header handling**: Different Accept headers for different endpoints
2. **Better error logging**: More detailed proxy error information
3. **Enhanced debugging**: New endpoint using Orthanc native API

## Expected Results After Deployment:

### ✅ Should Work:
- Study list loading in OHIF
- Series navigation
- Individual image loading via WADO-URI
- Viewport navigation and tools

### 🔍 Debugging Commands:

If issues persist, check:

```bash
# Orthanc container logs
sudo docker-compose logs orthanc

# Nginx container logs  
sudo docker-compose logs nginx

# OHIF server logs
pm2 logs ohif-viewer

# Test individual endpoints
curl -k -s https://dentax.globalpearlventures.com:4000/dicom-web/studies
curl -k -s https://dentax.globalpearlventures.com:4000/wado?requestType=WADO&studyUID=...
```

## Troubleshooting:

### If Orthanc containers fail to start:
```bash
cd /var/lib/orthanc
sudo docker-compose down
sudo docker-compose up -d
sudo docker-compose logs -f
```

### If OHIF still shows black screen:
1. Check browser developer console for specific errors
2. Check PM2 logs: `pm2 logs ohif-viewer`
3. Test individual WADO-URI requests
4. Verify study UID in browser URL matches available studies

The main improvement is that we're now handling DICOM-Web and WADO-URI as separate services in Nginx, which should resolve the content-type and endpoint conflicts that were causing the black screen.
