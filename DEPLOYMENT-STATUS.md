# OHIF-Orthanc Integration Status Report

## Issues Identified from Linux Test Results:

### 1. **Orthanc DICOM-Web Limitations**
- **Problem**: Orthanc's WADO-RS plugin has limited support for `application/dicom+json` content type
- **Evidence**: Error "This WADO-RS plugin cannot generate the following content type: application/dicom+json"
- **Impact**: Study metadata and instance metadata endpoints fail with 400 errors

### 2. **Missing Instance Data**
- **Problem**: Series response doesn't include instance information in DICOM-Web format
- **Evidence**: jq error when trying to access instances array, empty objectUID in WADO-URI test
- **Impact**: OHIF cannot load individual DICOM images

### 3. **WADO-URI Proxy Issues**
- **Problem**: WADO-URI requests return 404 errors
- **Evidence**: Test showed 404 response for WADO-URI endpoint
- **Impact**: Image rendering fails in OHIF viewer

## Fixes Applied:

### 1. **Enhanced WADO-URI Proxy**
- ✅ Added dedicated `/wado` endpoint handler
- ✅ Proper parameter transformation for Orthanc
- ✅ Binary data handling for DICOM files
- ✅ CORS headers for cross-origin requests

### 2. **Updated OHIF Configuration**
- ✅ Disabled `supportsInstanceMetadata` due to Orthanc limitations
- ✅ Disabled `supportsWildcard` for better Orthanc compatibility
- ✅ Forced `imageRendering: 'wadouri'` to bypass WADO-RS issues
- ✅ Added `bulkDataURI: { enabled: false }` to prevent bulk data issues

### 3. **Enhanced Debugging**
- ✅ New `/api/debug-orthanc-study/:studyUID` endpoint
- ✅ Uses Orthanc's native API to get complete study information
- ✅ Generates proper WADO-URI URLs with all required UIDs
- ✅ Tests WADO-URI connectivity directly

### 4. **Improved Error Handling**
- ✅ Better proxy error logging
- ✅ More detailed endpoint testing
- ✅ Enhanced deployment verification

## Deployment Steps:

1. **Commit and Push Changes**:
   ```bash
   git add .
   git commit -m "Fix Orthanc DICOM-Web compatibility and WADO-URI proxy"
   git push origin main
   ```

2. **Deploy to Linux Server**:
   ```bash
   chmod +x deploy-to-linux.sh
   ./deploy-to-linux.sh
   ```

3. **Test Enhanced Debugging**:
   ```bash
   chmod +x test-linux-endpoints.sh
   ./test-linux-endpoints.sh
   ```

4. **Test New Debug Endpoint**:
   ```bash
   # Get study UID from previous test
   STUDY_UID="1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6"
   curl -k -s "https://dentax.globalpearlventures.com:3000/api/debug-orthanc-study/$STUDY_UID" | jq .
   ```

## Expected Results After Deployment:

### ✅ Working Endpoints:
- `/dicom-web/studies` - Study list
- `/dicom-web/studies?StudyInstanceUID=...` - Specific study query
- `/dicom-web/studies/.../series` - Series list
- `/wado?requestType=WADO&...` - WADO-URI image retrieval

### ⚠️ Limited/Disabled Endpoints:
- `/dicom-web/studies/.../metadata` - Disabled due to Orthanc limitations
- `/dicom-web/studies/...` - Individual study metadata (limited support)
- Instance metadata queries - Disabled to prevent errors

## Key Configuration Changes:

### OHIF Data Source Configuration:
```javascript
{
  imageRendering: 'wadouri',           // Force WADO-URI for images
  thumbnailRendering: 'wadouri',       // Force WADO-URI for thumbnails
  supportsInstanceMetadata: false,     // Disable problematic metadata
  supportsWildcard: false,             // Disable for Orthanc compatibility
  bulkDataURI: { enabled: false },     // Prevent bulk data issues
}
```

### WADO-URI Endpoint:
- Custom proxy handler at `/wado`
- Proper binary data handling
- Direct integration with Orthanc's WADO endpoint

## Testing URL:
After deployment, test with:
`https://dentax.globalpearlventures.com:3000/viewer/dicomweb?StudyInstanceUIDs=1.3.12.2.1107.5.4.3.123456789012345.19950922.121803.6`

## Monitor Logs:
```bash
pm2 logs ohif-viewer --lines 50
```

The main goal is to work around Orthanc's DICOM-Web limitations by using WADO-URI for image retrieval while maintaining compatibility with OHIF's data source requirements.
