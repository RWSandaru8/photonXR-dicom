# Build and run OHIF Viewer with Orthanc Server

# Build the Docker image for OHIF Viewer
docker build -t ohif-viewer:latest --build-arg APP_CONFIG=config/orthanc-config.js .

# Run OHIF Viewer connected to Orthanc on port 4000
docker run -d \
  --name ohif-viewer \
  -p 3000:80 \
  -e PORT=80 \
  -e PUBLIC_URL=/ \
  ohif-viewer:latest

# If you have a separate Orthanc server running on port 4000, make sure it's accessible
# and has CORS enabled. If not, you can run Orthanc using:
docker run -d \
  --name orthanc-server \
  -p 4000:8042 \
  -p 4242:4242 \
  -v orthanc-db:/var/lib/orthanc/db \
  -v orthanc-storage:/var/lib/orthanc/storage \
  -v "$(pwd)/orthanc-config:/etc/orthanc/:ro" \
  -e ORTHANC__NAME=OHIF-Orthanc \
  -e ORTHANC__DICOM_WEB__ENABLE=true \
  -e ORTHANC__DICOM_WEB__ROOT=/dicom-web/ \
  -e ORTHANC__AUTHENTICATION_ENABLED=false \
  -e ORTHANC__HTTP_CORS__ENABLED=true \
  -e ORTHANC__HTTP_CORS__ALLOWED_ORIGINS=* \
  orthancteam/orthanc:latest
