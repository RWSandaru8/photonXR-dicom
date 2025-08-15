# syntax=docker/dockerfile:1.7-labs
# This dockerfile is used to publish the `ohif/app` image on dockerhub.
#
# It's a good example of how to build our static application and package it
# with a web server capable of hosting it as static content.
#
# docker build
# --------------
# If you would like to use this dockerfile to build and tag an image, make sure
# you set the context to the project's root directory:
# https://docs.docker.com/engine/reference/commandline/build/
#
#
# SUMMARY
# --------------
# This dockerfile has two stages:
#
# 1. Building the React application for production
# 2. Setting up our Nginx (Alpine Linux) image w/ step one's output
#


# syntax=docker/dockerfile:1.7-labs
# This dockerfile is used to publish the `ohif/app` image on dockerhub.
#
# It's a good example of how to build our static application and package it
# with a web server capable of hosting it as static content.
#
# docker build
# --------------
# If you would like to use this dockerfile to build and tag an image, make sure
# you set the context to the project's root directory:
# https://docs.docker.com/engine/reference/commandline/build/
#
#
# SUMMARY
# --------------
# This dockerfile is used as an input for a second stage to make things run faster.
#


# Stage 1: Build the application
# docker build -t ohif/viewer:latest .
# Copy Files
FROM node:20.18.1-slim as builder

# Install dependencies in one layer and clean up
RUN apt-get update && apt-get install -y build-essential python3 && \
    rm -rf /var/lib/apt/lists/* && \
    apt-get clean

WORKDIR /usr/src/app
RUN command -v yarn >/dev/null 2>&1 || npm install -g yarn
ENV PATH=/usr/src/app/node_modules/.bin:$PATH

# Do an initial install and then a final install
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
RUN chmod +x .docker/compressDist.sh && ./.docker/compressDist.sh

# Stage 2: Production nginx server
FROM nginxinc/nginx-unprivileged:1.27-alpine as final

# Set build args and environment variables
ARG PUBLIC_URL=/
ARG PORT=3000
ENV PUBLIC_URL=${PUBLIC_URL}
ENV PORT=${PORT}

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

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:${PORT}/ || exit 1

EXPOSE ${PORT}
ENTRYPOINT ["/usr/src/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
