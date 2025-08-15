#!/bin/bash
#
# OHIF Native Build & Serve Script (No Docker)
# This script builds OHIF natively and serves it on port 3000
#
# Usage:
#   ./build-native.sh [command]
#
# Commands:
#   install   - Install dependencies
#   build     - Build the application
#   serve     - Serve the built application on port 3000
#   dev       - Start development server
#   clean     - Clean build artifacts
#   full      - Install + Build + Serve
#

set -e  # Exit on any error

# Configuration
PORT=3000
PUBLIC_URL="/"
NODE_ENV="production"
APP_CONFIG="config/orthanc-config.js"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "${BLUE}[STEP]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_step "Checking prerequisites..."
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
    
    # Check Node version
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        log_error "Node.js version 18 or higher is required. Current version: $(node -v)"
        exit 1
    fi
    
    # Check yarn
    if ! command -v yarn &> /dev/null; then
        log_info "Yarn not found, installing..."
        npm install -g yarn
    fi
    
    # Check if we're in the right directory
    if [ ! -f "package.json" ] || [ ! -d "platform" ]; then
        log_error "Please run this script from the OHIF project root directory"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
    log_info "Node.js version: $(node -v)"
    log_info "Yarn version: $(yarn -v)"
}

# Install dependencies
install_dependencies() {
    log_step "Installing dependencies..."
    
    # Clean any existing node_modules
    log_info "Cleaning existing node_modules..."
    rm -rf node_modules
    
    # Install dependencies
    log_info "Installing project dependencies..."
    yarn install --frozen-lockfile
    
    log_info "Dependencies installed successfully"
}

# Setup configuration
setup_config() {
    log_step "Setting up configuration..."
    
    # Ensure the config directory exists
    mkdir -p platform/app/public/config
    
    # Copy config from root config/ to platform/app/public/config/
    if [ -f "config/orthanc-config.js" ]; then
        log_info "Copying Orthanc configuration..."
        cp config/orthanc-config.js platform/app/public/config/
    else
        log_error "Config file not found: config/orthanc-config.js"
        log_info "Creating default Orthanc config..."
        create_default_config
    fi
    
    log_info "Configuration setup completed"
}

# Create default config if missing
create_default_config() {
    mkdir -p config
    cat > config/orthanc-config.js << 'EOF'
/** @type {AppTypes.Config} */
window.config = {
  name: 'config/orthanc-config.js',
  routerBasename: null,
  extensions: [],
  modes: [],
  customizationService: {},
  showStudyList: true,
  maxNumberOfWebWorkers: 3,
  showWarningMessageForCrossOrigin: true,
  showCPUFallbackMessage: true,
  showLoadingIndicator: true,
  strictZSpacingForVolumeViewport: true,
  
  defaultDataSourceName: 'orthanc',
  
  dataSources: [
    {
      namespace: '@ohif/extension-default.dataSourcesModule.dicomweb',
      sourceName: 'orthanc',
      configuration: {
        friendlyName: 'Local Orthanc DICOMWeb Server',
        name: 'Orthanc',
        wadoUriRoot: 'http://localhost:4000/dicom-web',
        qidoRoot: 'http://localhost:4000/dicom-web',
        wadoRoot: 'http://localhost:4000/dicom-web',
        qidoSupportsIncludeField: true,
        supportsReject: true,
        dicomUploadEnabled: true,
        imageRendering: 'wadors',
        thumbnailRendering: 'wadors',
        enableStudyLazyLoad: true,
        supportsFuzzyMatching: true,
        supportsWildcard: true,
        staticWado: false,
        singlepart: 'bulkdata,video',
        omitQuotationForMultipartRequest: true,
        requestOptions: {
          requestCredentials: 'omit',
        },
        bulkDataURI: {
          enabled: true,
          relativeResolution: 'studies',
        },
      },
    },
  ],
  
  httpErrorHandler: error => {
    console.warn('HTTP Error Status:', error.status);
    if (error.status === 0) {
      console.error('Network error or CORS issue. Please check if Orthanc server is running and CORS is properly configured.');
    }
  },
};
EOF
    
    # Copy to build location
    mkdir -p platform/app/public/config
    cp config/orthanc-config.js platform/app/public/config/
    log_info "Default Orthanc config created"
}

# Build application
build_app() {
    log_step "Building OHIF application..."
    
    # Setup configuration
    setup_config
    
    # Set environment variables
    export NODE_ENV="production"
    export PUBLIC_URL="/"
    export GENERATE_SOURCEMAP=false
    export NODE_OPTIONS="--max-old-space-size=4096"
    
    log_info "Building with configuration:"
    log_info "  NODE_ENV: $NODE_ENV"
    log_info "  PUBLIC_URL: $PUBLIC_URL"
    log_info "  APP_CONFIG: $APP_CONFIG"
    
    # Show current config
    yarn run show:config
    
    # Build the application
    log_info "Starting build process..."
    yarn run build
    
    log_info "Build completed successfully!"
    log_info "Built files are in: platform/app/dist/"
}

# Serve application
serve_app() {
    log_step "Starting OHIF server on port $PORT..."
    
    # Check if build exists
    if [ ! -d "platform/app/dist" ]; then
        log_error "Build directory not found. Please run build first."
        exit 1
    fi
    
    # Install serve if not available
    if ! command -v serve &> /dev/null; then
        log_info "Installing serve globally..."
        npm install -g serve
    fi
    
    # Start the server
    log_info "=== OHIF Server Starting ==="
    log_info "URL: http://localhost:$PORT"
    log_info "Build: platform/app/dist/"
    log_info "Config: Orthanc on http://localhost:4000"
    log_info "============================"
    
    # Serve the application
    cd platform/app/dist
    serve -s . -p $PORT
}

# Development server
dev_server() {
    log_step "Starting development server..."
    
    # Setup configuration
    setup_config
    
    # Set environment variables
    export NODE_ENV="development"
    export PUBLIC_URL="/"
    export PORT=$PORT
    
    log_info "Starting development server on port $PORT..."
    log_info "Development mode - hot reloading enabled"
    
    # Start development server
    cd platform/app
    yarn start
}

# Clean build artifacts
clean_build() {
    log_step "Cleaning build artifacts..."
    
    # Remove build directories
    rm -rf platform/app/dist
    rm -rf platform/app/build
    rm -rf .parcel-cache
    rm -rf node_modules/.cache
    
    # Remove yarn cache
    yarn cache clean
    
    log_info "Clean completed"
}

# Check if Orthanc is running
check_orthanc() {
    log_step "Checking Orthanc server..."
    
    if curl -s http://localhost:4000/system > /dev/null 2>&1; then
        log_info "✓ Orthanc server is running at http://localhost:4000"
        return 0
    else
        log_warn "✗ Orthanc server is not accessible at http://localhost:4000"
        log_info "Please make sure Orthanc server is running with DICOMWeb enabled"
        log_info "You can start Orthanc with Docker:"
        echo "  docker run -p 4000:8042 -p 4242:4242 \\"
        echo "    -e ORTHANC__DICOM_WEB__ENABLE=true \\"
        echo "    -e ORTHANC__HTTP_CORS__ENABLED=true \\"
        echo "    orthancteam/orthanc:latest"
        return 1
    fi
}

# Show access information
show_access_info() {
    log_info "=== Access Information ==="
    echo "OHIF Viewer:         http://localhost:$PORT"
    echo "Orthanc Web UI:      http://localhost:4000"
    echo "Orthanc DICOMWeb:    http://localhost:4000/dicom-web"
    echo "DICOM C-STORE Port:  4242"
    echo "=========================="
}

# Full deployment
full_deployment() {
    log_step "Starting full native deployment..."
    
    install_dependencies
    build_app
    
    log_info "Build completed! You can now:"
    log_info "1. Start Orthanc server (if not running)"
    log_info "2. Run: ./build-native.sh serve"
    
    # Check if Orthanc is running
    check_orthanc
    
    log_info "Full deployment preparation completed!"
    log_info "Run './build-native.sh serve' to start the server"
}

# Start Orthanc with Docker (helper function)
start_orthanc() {
    log_step "Starting Orthanc server with Docker..."
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker or start Orthanc manually."
        exit 1
    fi
    
    # Stop any existing Orthanc container
    docker stop orthanc-server 2>/dev/null || true
    docker rm orthanc-server 2>/dev/null || true
    
    # Start Orthanc
    log_info "Starting Orthanc on port 4000..."
    docker run -d \
        --name orthanc-server \
        -p 4000:8042 \
        -p 4242:4242 \
        -v orthanc-db:/var/lib/orthanc/db \
        -v orthanc-storage:/var/lib/orthanc/storage \
        -e ORTHANC__NAME=OHIF-Orthanc \
        -e ORTHANC__DICOM_WEB__ENABLE=true \
        -e ORTHANC__DICOM_WEB__ROOT=/dicom-web/ \
        -e ORTHANC__AUTHENTICATION_ENABLED=false \
        -e ORTHANC__HTTP_CORS__ENABLED=true \
        -e ORTHANC__HTTP_CORS__ALLOWED_ORIGINS=* \
        -e ORTHANC__HTTP_CORS__ALLOWED_METHODS=GET,POST,PUT,DELETE,OPTIONS \
        -e ORTHANC__HTTP_CORS__ALLOWED_HEADERS=* \
        orthancteam/orthanc:latest
    
    log_info "Waiting for Orthanc to start..."
    sleep 10
    
    if check_orthanc; then
        log_info "Orthanc started successfully!"
    else
        log_error "Failed to start Orthanc"
        exit 1
    fi
}

# Main script logic
main() {
    echo "================================================"
    echo "OHIF Native Build & Serve Script (No Docker)"
    echo "================================================"
    
    case "${1:-help}" in
        "install")
            check_prerequisites
            install_dependencies
            ;;
        "build")
            check_prerequisites
            build_app
            ;;
        "serve")
            serve_app
            ;;
        "dev")
            check_prerequisites
            dev_server
            ;;
        "clean")
            clean_build
            ;;
        "full")
            check_prerequisites
            full_deployment
            ;;
        "orthanc")
            start_orthanc
            ;;
        "start")
            check_prerequisites
            full_deployment
            echo ""
            log_info "Starting OHIF server..."
            serve_app
            ;;
        "help"|*)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  install   - Install dependencies"
            echo "  build     - Build the application"
            echo "  serve     - Serve the built application on port $PORT"
            echo "  dev       - Start development server with hot reload"
            echo "  clean     - Clean build artifacts"
            echo "  full      - Install + Build (prepare for serving)"
            echo "  orthanc   - Start Orthanc server with Docker"
            echo "  start     - Complete setup: install + build + serve"
            echo "  help      - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 start              # Complete setup and start server"
            echo "  $0 full && $0 serve   # Build then serve"
            echo "  $0 dev                # Development mode"
            echo "  $0 orthanc            # Start Orthanc server"
            echo ""
            echo "After building, OHIF will be available at:"
            echo "  http://localhost:$PORT"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
