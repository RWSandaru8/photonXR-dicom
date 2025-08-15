#!/bin/bash
#
# OHIF + Orthanc Production Build & Deployment Script
# This script provides backup, build, and deployment functionality
#
# Usage:
#   ./deploy-ohif.sh [command]
#
# Commands:
#   build     - Build the Docker images
#   start     - Start the services
#   stop      - Stop the services
#   restart   - Restart the services
#   backup    - Backup Orthanc data
#   restore   - Restore Orthanc data from backup
#   logs      - Show logs
#   status    - Show service status
#   clean     - Clean up everything
#   full      - Full deployment (backup + build + start)
#

set -e  # Exit on any error

# Configuration
PROJECT_NAME="ohif-dicom"
BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
COMPOSE_FILE="docker-compose.yml"
PROD_COMPOSE_FILE="docker-compose.prod.yml"

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
    
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        log_error "Docker Compose is not installed"
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running"
        exit 1
    fi
    
    log_info "Prerequisites check passed"
}

# Create backup directory
ensure_backup_dir() {
    mkdir -p "$BACKUP_DIR"
    log_info "Backup directory ready: $BACKUP_DIR"
}

# Backup function
backup_data() {
    log_step "Starting backup process..."
    ensure_backup_dir
    
    # Check if containers exist
    if docker volume ls | grep -q "${PROJECT_NAME}_orthanc-db"; then
        log_info "Backing up Orthanc database..."
        docker run --rm \
            -v "${PROJECT_NAME}_orthanc-db:/data" \
            -v "$(pwd)/$BACKUP_DIR:/backup" \
            alpine tar czf "/backup/orthanc-db-${TIMESTAMP}.tar.gz" -C /data .
        
        log_info "Database backup completed: orthanc-db-${TIMESTAMP}.tar.gz"
    else
        log_warn "Orthanc database volume not found, skipping database backup"
    fi
    
    if docker volume ls | grep -q "${PROJECT_NAME}_orthanc-storage"; then
        log_info "Backing up Orthanc storage..."
        docker run --rm \
            -v "${PROJECT_NAME}_orthanc-storage:/data" \
            -v "$(pwd)/$BACKUP_DIR:/backup" \
            alpine tar czf "/backup/orthanc-storage-${TIMESTAMP}.tar.gz" -C /data .
        
        log_info "Storage backup completed: orthanc-storage-${TIMESTAMP}.tar.gz"
    else
        log_warn "Orthanc storage volume not found, skipping storage backup"
    fi
    
    # Backup configuration
    log_info "Backing up configuration..."
    tar czf "$BACKUP_DIR/config-${TIMESTAMP}.tar.gz" \
        config/ \
        orthanc-config/ \
        docker-compose.yml \
        docker-compose.prod.yml \
        Dockerfile \
        2>/dev/null || log_warn "Some config files missing, partial backup created"
    
    log_info "Configuration backup completed: config-${TIMESTAMP}.tar.gz"
    log_info "Backup process completed successfully"
}

# Restore function
restore_data() {
    log_step "Starting restore process..."
    
    if [ -z "$1" ]; then
        log_error "Please specify timestamp for restore (format: YYYYMMDD_HHMMSS)"
        log_info "Available backups:"
        ls -la "$BACKUP_DIR"/*.tar.gz 2>/dev/null || log_warn "No backups found"
        exit 1
    fi
    
    RESTORE_TIMESTAMP="$1"
    
    log_warn "This will overwrite existing data. Continue? (y/N)"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Restore cancelled"
        exit 0
    fi
    
    # Stop services first
    stop_services
    
    # Restore database
    if [ -f "$BACKUP_DIR/orthanc-db-${RESTORE_TIMESTAMP}.tar.gz" ]; then
        log_info "Restoring Orthanc database..."
        docker run --rm \
            -v "${PROJECT_NAME}_orthanc-db:/data" \
            -v "$(pwd)/$BACKUP_DIR:/backup" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/orthanc-db-${RESTORE_TIMESTAMP}.tar.gz -C /data"
        log_info "Database restore completed"
    else
        log_warn "Database backup not found: orthanc-db-${RESTORE_TIMESTAMP}.tar.gz"
    fi
    
    # Restore storage
    if [ -f "$BACKUP_DIR/orthanc-storage-${RESTORE_TIMESTAMP}.tar.gz" ]; then
        log_info "Restoring Orthanc storage..."
        docker run --rm \
            -v "${PROJECT_NAME}_orthanc-storage:/data" \
            -v "$(pwd)/$BACKUP_DIR:/backup" \
            alpine sh -c "rm -rf /data/* && tar xzf /backup/orthanc-storage-${RESTORE_TIMESTAMP}.tar.gz -C /data"
        log_info "Storage restore completed"
    else
        log_warn "Storage backup not found: orthanc-storage-${RESTORE_TIMESTAMP}.tar.gz"
    fi
    
    log_info "Restore process completed"
}

# Build function
build_images() {
    log_step "Building Docker images..."
    
    # Check if config files exist
    if [ ! -f "platform/app/public/config/orthanc-config.js" ]; then
        if [ -f "config/orthanc-config.js" ]; then
            log_info "Copying config from config/ to platform/app/public/config/"
            mkdir -p platform/app/public/config/
            cp config/orthanc-config.js platform/app/public/config/
        else
            log_error "Orthanc config file not found in config/ or platform/app/public/config/"
            exit 1
        fi
    fi
    
    # Build with BuildKit for better performance
    export DOCKER_BUILDKIT=1
    export COMPOSE_DOCKER_CLI_BUILD=1
    
    log_info "Building OHIF Viewer image..."
    docker-compose build --no-cache --parallel ohif-viewer
    
    log_info "Pulling Orthanc image..."
    docker-compose pull orthanc
    
    log_info "Build completed successfully"
}

# Start services
start_services() {
    log_step "Starting services..."
    
    # Choose compose file based on SSL cert existence
    COMPOSE_CMD="docker-compose"
    if [ -d "/etc/letsencrypt/live" ] && [ "$USE_SSL" = "true" ]; then
        log_info "SSL certificates found, using production configuration"
        COMPOSE_CMD="docker-compose -f $PROD_COMPOSE_FILE"
    fi
    
    $COMPOSE_CMD up -d
    
    # Wait for services to be healthy
    log_info "Waiting for services to become healthy..."
    sleep 30
    
    # Check service status
    check_health
    
    log_info "Services started successfully"
    show_access_info
}

# Stop services
stop_services() {
    log_step "Stopping services..."
    docker-compose down
    log_info "Services stopped"
}

# Restart services
restart_services() {
    log_step "Restarting services..."
    stop_services
    start_services
}

# Check health
check_health() {
    log_step "Checking service health..."
    
    # Check OHIF
    if curl -s http://localhost:3000/health > /dev/null 2>&1; then
        log_info "✓ OHIF Viewer is healthy"
    else
        log_warn "✗ OHIF Viewer health check failed"
    fi
    
    # Check Orthanc
    if curl -s http://localhost:4000/system > /dev/null 2>&1; then
        log_info "✓ Orthanc server is healthy"
    else
        log_warn "✗ Orthanc server health check failed"
    fi
}

# Show access information
show_access_info() {
    log_info "=== Access Information ==="
    echo "OHIF Viewer (HTTP):  http://localhost:3000"
    echo "Orthanc Web UI:      http://localhost:4000"
    echo "Orthanc DICOMWeb:    http://localhost:4000/dicom-web"
    echo "DICOM C-STORE Port:  4242"
    
    if [ -d "/etc/letsencrypt/live" ] && [ "$USE_SSL" = "true" ]; then
        echo "OHIF Viewer (HTTPS): https://dentax.globalpearlventures.com:3443"
    fi
    
    echo "=========================="
}

# Show logs
show_logs() {
    log_step "Showing service logs..."
    if [ -n "$1" ]; then
        docker-compose logs -f "$1"
    else
        docker-compose logs -f
    fi
}

# Show status
show_status() {
    log_step "Service Status:"
    docker-compose ps
    
    log_step "Container Resource Usage:"
    docker stats --no-stream $(docker-compose ps -q) 2>/dev/null || log_info "No running containers"
    
    log_step "Volume Usage:"
    docker volume ls | grep "${PROJECT_NAME}" || log_info "No volumes found"
}

# Clean up everything
clean_all() {
    log_step "Cleaning up everything..."
    
    log_warn "This will remove all containers, images, and volumes. Continue? (y/N)"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        log_info "Clean cancelled"
        exit 0
    fi
    
    # Stop and remove everything
    docker-compose down -v --rmi all --remove-orphans
    
    # Clean up dangling images
    docker image prune -f
    docker volume prune -f
    
    log_info "Cleanup completed"
}

# Full deployment
full_deployment() {
    log_step "Starting full deployment..."
    
    backup_data
    build_images
    start_services
    
    log_info "Full deployment completed successfully!"
}

# Main script logic
main() {
    echo "================================================"
    echo "OHIF + Orthanc Production Deployment Script"
    echo "================================================"
    
    check_prerequisites
    
    case "${1:-help}" in
        "build")
            build_images
            ;;
        "start")
            start_services
            ;;
        "stop")
            stop_services
            ;;
        "restart")
            restart_services
            ;;
        "backup")
            backup_data
            ;;
        "restore")
            restore_data "$2"
            ;;
        "logs")
            show_logs "$2"
            ;;
        "status")
            show_status
            ;;
        "health")
            check_health
            ;;
        "clean")
            clean_all
            ;;
        "full")
            full_deployment
            ;;
        "help"|*)
            echo "Usage: $0 [command]"
            echo ""
            echo "Commands:"
            echo "  build     - Build Docker images"
            echo "  start     - Start services"
            echo "  stop      - Stop services"
            echo "  restart   - Restart services"
            echo "  backup    - Backup Orthanc data and config"
            echo "  restore   - Restore from backup (requires timestamp)"
            echo "  logs      - Show logs (optional: specify service name)"
            echo "  status    - Show service status and resource usage"
            echo "  health    - Check service health"
            echo "  clean     - Clean up everything (destructive!)"
            echo "  full      - Full deployment (backup + build + start)"
            echo "  help      - Show this help message"
            echo ""
            echo "Examples:"
            echo "  $0 full                    # Complete deployment"
            echo "  $0 backup                 # Backup data"
            echo "  $0 restore 20240815_143000 # Restore from specific backup"
            echo "  $0 logs ohif-viewer       # Show OHIF logs"
            echo "  $0 logs orthanc-server    # Show Orthanc logs"
            echo ""
            echo "Environment variables:"
            echo "  USE_SSL=true              # Enable SSL mode"
            ;;
    esac
}

# Run main function with all arguments
main "$@"
