# syntax=docker/dockerfile:1.7-labs
# Production-ready OHIF Viewer with Orthanc integration
# Build: docker build -t ohif-viewer:latest .
# Run: docker run -p 3000:80 ohif-viewer:latest

# Stage 1: Build the application
FROM node:20.18.1-slim as builder

# Install system dependencies and clean up in one layer
RUN apt-get update && apt-get install -y \
    build-essential \
    python3 \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

WORKDIR /usr/src/app

# Install package managers
RUN command -v yarn >/dev/null 2>&1 || npm install -g yarn

# Set environment for optimization
ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false
ENV NODE_OPTIONS="--max-old-space-size=4096"
ENV PATH=/usr/src/app/node_modules/.bin:$PATH

# Copy package files for dependency installation (better Docker layer caching)
COPY package.json yarn.lock preinstall.js lerna.json ./

# Copy package.json files in batches to optimize Docker layer caching
COPY ./addOns/package.json ./addOns/package.json
COPY ./addOns/externals/devDependencies/package.json ./addOns/externals/devDependencies/package.json
COPY ./addOns/externals/dicom-microscopy-viewer/package.json ./addOns/externals/dicom-microscopy-viewer/package.json

# Extensions package.json files
COPY ./extensions/cornerstone/package.json ./extensions/cornerstone/package.json
COPY ./extensions/cornerstone-dicom-pmap/package.json ./extensions/cornerstone-dicom-pmap/package.json
COPY ./extensions/cornerstone-dicom-rt/package.json ./extensions/cornerstone-dicom-rt/package.json
COPY ./extensions/cornerstone-dicom-seg/package.json ./extensions/cornerstone-dicom-seg/package.json
COPY ./extensions/cornerstone-dicom-sr/package.json ./extensions/cornerstone-dicom-sr/package.json
COPY ./extensions/cornerstone-dynamic-volume/package.json ./extensions/cornerstone-dynamic-volume/package.json
COPY ./extensions/default/package.json ./extensions/default/package.json
COPY ./extensions/dicom-microscopy/package.json ./extensions/dicom-microscopy/package.json
COPY ./extensions/dicom-pdf/package.json ./extensions/dicom-pdf/package.json
COPY ./extensions/dicom-video/package.json ./extensions/dicom-video/package.json
COPY ./extensions/measurement-tracking/package.json ./extensions/measurement-tracking/package.json
COPY ./extensions/test-extension/package.json ./extensions/test-extension/package.json
COPY ./extensions/tmtv/package.json ./extensions/tmtv/package.json

# Modes package.json files
COPY ./modes/basic-dev-mode/package.json ./modes/basic-dev-mode/package.json
COPY ./modes/basic-test-mode/package.json ./modes/basic-test-mode/package.json
COPY ./modes/longitudinal/package.json ./modes/longitudinal/package.json
COPY ./modes/microscopy/package.json ./modes/microscopy/package.json
COPY ./modes/preclinical-4d/package.json ./modes/preclinical-4d/package.json
COPY ./modes/segmentation/package.json ./modes/segmentation/package.json
COPY ./modes/tmtv/package.json ./modes/tmtv/package.json

# Platform package.json files
COPY ./platform/app/package.json ./platform/app/package.json
COPY ./platform/cli/package.json ./platform/cli/package.json
COPY ./platform/core/package.json ./platform/core/package.json
COPY ./platform/i18n/package.json ./platform/i18n/package.json
COPY ./platform/ui/package.json ./platform/ui/package.json
COPY ./platform/ui-next/package.json ./platform/ui-next/package.json

# Install dependencies (this is the slowest step, so we do it after copying package.json files)
RUN yarn install --frozen-lockfile --network-timeout 300000 --prefer-offline

# Copy source code (this will invalidate cache only when source changes)
COPY . .

# Build the application with optimized settings
ENV QUICK_BUILD=true
ENV NODE_ENV=production
ENV GENERATE_SOURCEMAP=false
ARG APP_CONFIG=config/orthanc-config.js
ARG PUBLIC_URL=/
ENV PUBLIC_URL=${PUBLIC_URL}
ENV APP_CONFIG=${APP_CONFIG}

# Verify config file exists before building
RUN echo "Checking for config file at platform/app/public/${APP_CONFIG}..." && \
    ls -la platform/app/public/config/ && \
    test -f "platform/app/public/${APP_CONFIG}" || (echo "Config file not found at platform/app/public/${APP_CONFIG}" && exit 1)

# Build with increased memory and optimizations
RUN NODE_OPTIONS="--max-old-space-size=4096" yarn run show:config
RUN NODE_OPTIONS="--max-old-space-size=4096" yarn run build

# Precompress files for better nginx performance
RUN echo "Compressing static files..." && \
    cd platform/app/dist && \
    find . -name "*.js" -type f -exec gzip -9 -k {} \; && \
    find . -name "*.css" -type f -exec gzip -9 -k {} \; && \
    find . -name "*.svg" -type f -exec gzip -9 -k {} \; && \
    find . -name "*.html" -type f -exec gzip -9 -k {} \; && \
    echo "Compression completed" || echo "Compression failed, continuing without compression"

# Stage 2: Production nginx server
FROM nginxinc/nginx-unprivileged:1.27-alpine as final

# Set build args and environment variables
ARG PUBLIC_URL=/
ARG PORT=80
ARG SSL_PORT=443
ENV PUBLIC_URL=${PUBLIC_URL}
ENV PORT=${PORT}
ENV SSL_PORT=${SSL_PORT}

# Configure nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copy nginx configuration and scripts
USER nginx
COPY --chown=nginx:nginx .docker/Viewer-v3.x /usr/src
RUN chmod +x /usr/src/entrypoint.sh

# Copy built application from builder stage
COPY --from=builder --chown=nginx:nginx /usr/src/app/platform/app/dist /usr/share/nginx/html${PUBLIC_URL}

# Copy microscopy viewer (required for certain DICOM types)
COPY --from=builder --chown=nginx:nginx /usr/src/app/platform/app/dist/dicom-microscopy-viewer /usr/share/nginx/html/dicom-microscopy-viewer

# Final permissions setup
USER root
RUN chown -R nginx:nginx /usr/share/nginx/html
USER nginx

# Health check - use port 80 internally
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --quiet --tries=1 --spider http://localhost:80/health || exit 1

EXPOSE 80 443
ENTRYPOINT ["/usr/src/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
