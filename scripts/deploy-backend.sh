# ===================================================================
# BACKEND DEPLOYMENT SCRIPT - scripts/deploy-backend.sh
# ===================================================================

#!/bin/bash

set -e  # Exit on any error

echo "🚀 Starting AgentCraft Backend Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_DIR="backend"
RAILWAY_PROJECT_NAME="agentcraft-backend"
RENDER_SERVICE_NAME="agentcraft-api"
BACKUP_DIR="backups/backend-$(date +%Y%m%d-%H%M%S)"

# Functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [ ! -d "$BACKEND_DIR" ]; then
        log_error "Backend directory not found. Are you in the project root?"
        exit 1
    fi
    
    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is not installed. Please install Node.js 18+ first."
        exit 1
    fi
    
    # Check Node.js version
    NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        log_error "Node.js 18+ is required. Current version: $(node --version)"
        exit 1
    fi
    
    # Check environment file
    if [ ! -f "$BACKEND_DIR/.env" ]; then
        log_warning "No .env file found. Make sure to set environment variables in your deployment platform."
    fi
    
    log_success "Prerequisites check passed"
}

backup_current() {
    log_info "Creating backup of current backend..."
    
    mkdir -p "$BACKUP_DIR"
    
    # Backup important files
    if [ -f "$BACKEND_DIR/prisma/dev.db" ]; then
        cp "$BACKEND_DIR/prisma/dev.db" "$BACKUP_DIR/"
        log_success "Database backup created"
    fi
    
    if [ -d "$BACKEND_DIR/logs" ]; then
        cp -r "$BACKEND_DIR/logs" "$BACKUP_DIR/"
        log_success "Logs backup created"
    fi
    
    log_success "Backup created at $BACKUP_DIR"
}

install_dependencies() {
    log_info "Installing backend dependencies..."
    
    cd "$BACKEND_DIR"
    
    # Clean install
    if [ -f "package-lock.json" ]; then
        npm ci --only=production
    else
        npm install --only=production
    fi
    
    log_success "Dependencies installed"
    cd ..
}

setup_database() {
    log_info "Setting up database..."
    
    cd "$BACKEND_DIR"
    
    # Generate Prisma client
    npx prisma generate
    
    # Run database migrations
    if [ "$NODE_ENV" = "production" ]; then
        npx prisma migrate deploy
    else
        npx prisma db push
    fi
    
    log_success "Database setup completed"
    cd ..
}

run_tests() {
    log_info "Running backend tests..."
    
    cd "$BACKEND_DIR"
    
    # Install dev dependencies for testing
    npm install
    
    # Run linting
    if npm run lint &> /dev/null; then
        log_success "Linting passed"
    else
        log_warning "Linting issues found, but continuing..."
    fi
    
    # Run tests if available
    if grep -q '"test"' package.json; then
        if npm test; then
            log_success "Tests passed"
        else
            log_error "Tests failed"
            cd ..
            exit 1
        fi
    else
        log_warning "No tests configured"
    fi
    
    cd ..
}

check_health() {
    log_info "Checking application health..."
    
    cd "$BACKEND_DIR"
    
    # Start the application in background
    npm start &
    APP_PID=$!
    
    # Wait for startup
    sleep 10
    
    # Check health endpoint
    if curl -f http://localhost:5000/api/health &> /dev/null; then
        log_success "Health check passed"
    else
        log_warning "Health check failed, but continuing..."
    fi
    
    # Stop the application
    kill $APP_PID 2>/dev/null || true
    
    cd ..
}

deploy_to_railway() {
    log_info "Deploying to Railway..."
    
    # Check if Railway CLI is installed
    if ! command -v railway &> /dev/null; then
        log_warning "Railway CLI not found. Installing..."
        
        # Install Railway CLI
        if command -v curl &> /dev/null; then
            curl -fsSL https://railway.app/install.sh | sh
        else
            log_error "curl is required to install Railway CLI"
            exit 1
        fi
    fi
    
    cd "$BACKEND_DIR"
    
    # Login check
    if ! railway status &> /dev/null; then
        log_error "Not logged in to Railway. Please run: railway login"
        cd ..
        exit 1
    fi
    
    # Deploy to Railway
    if railway up; then
        log_success "Successfully deployed to Railway"
        
        # Get deployment URL
        DEPLOYMENT_URL=$(railway status | grep "URL" | awk '{print $2}')
        if [ ! -z "$DEPLOYMENT_URL" ]; then
            log_success "Deployment URL: $DEPLOYMENT_URL"
        fi
    else
        log_error "Railway deployment failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

deploy_to_render() {
    log_info "Deploying to Render..."
    
    # Check if Render CLI is installed
    if ! command -v render &> /dev/null; then
        log_warning "Render CLI not found. Please deploy via Git push or Render dashboard."
        log_info "Make sure your repository is connected to Render"
        log_info "Push your changes to the main branch to trigger deployment"
        return 0
    fi
    
    cd "$BACKEND_DIR"
    
    # Deploy using Render CLI (if available)
    if render deploy; then
        log_success "Successfully deployed to Render"
    else
        log_error "Render deployment failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

deploy_to_docker() {
    log_info "Building and deploying Docker container..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed"
        exit 1
    fi
    
    # Build Docker image
    docker build -t agentcraft-backend:latest "$BACKEND_DIR"
    
    if [ $? -eq 0 ]; then
        log_success "Docker image built successfully"
    else
        log_error "Docker build failed"
        exit 1
    fi
    
    # Optional: Push to registry
    if [ ! -z "$DOCKER_REGISTRY" ]; then
        log_info "Pushing to Docker registry..."
        docker tag agentcraft-backend:latest "$DOCKER_REGISTRY/agentcraft-backend:latest"
        docker push "$DOCKER_REGISTRY/agentcraft-backend:latest"
        log_success "Image pushed to registry"
    fi
}

deploy_to_vps() {
    log_info "Deploying to VPS..."
    
    # Check required environment variables
    if [ -z "$VPS_HOST" ] || [ -z "$VPS_USER" ]; then
        log_error "VPS_HOST and VPS_USER environment variables are required"
        exit 1
    fi
    
    # Create deployment package
    DEPLOY_PACKAGE="agentcraft-backend-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$DEPLOY_PACKAGE" "$BACKEND_DIR" --exclude=node_modules --exclude=.git
    
    # Copy to VPS
    scp "$DEPLOY_PACKAGE" "$VPS_USER@$VPS_HOST:/tmp/"
    
    # Deploy on VPS
    ssh "$VPS_USER@$VPS_HOST" << EOF
        cd /var/www/agentcraft-backend
        tar -xzf "/tmp/$DEPLOY_PACKAGE" --strip-components=1
        npm ci --only=production
        npx prisma generate
        npx prisma migrate deploy
        pm2 restart agentcraft-backend || pm2 start server.js --name agentcraft-backend
EOF
    
    # Cleanup
    rm "$DEPLOY_PACKAGE"
    
    log_success "Successfully deployed to VPS"
}

show_help() {
    echo "AgentCraft Backend Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --railway    Deploy to Railway (default)"
    echo "  --render     Deploy to Render"
    echo "  --docker     Build Docker image"
    echo "  --vps        Deploy to VPS (requires VPS_HOST and VPS_USER env vars)"
    echo "  --no-test    Skip running tests"
    echo "  --no-backup  Skip creating backup"
    echo "  --no-health  Skip health check"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy to Railway with all checks"
    echo "  $0 --render          # Deploy to Render"
    echo "  $0 --docker          # Build Docker image"
    echo "  $0 --no-test         # Skip tests and deploy to Railway"
}

# Main deployment function
main() {
    local DEPLOYMENT_TARGET="railway"
    local RUN_TESTS=true
    local CREATE_BACKUP=true
    local CHECK_HEALTH=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --railway)
                DEPLOYMENT_TARGET="railway"
                shift
                ;;
            --render)
                DEPLOYMENT_TARGET="render"
                shift
                ;;
            --docker)
                DEPLOYMENT_TARGET="docker"
                shift
                ;;
            --vps)
                DEPLOYMENT_TARGET="vps"
                shift
                ;;
            --no-test)
                RUN_TESTS=false
                shift
                ;;
            --no-backup)
                CREATE_BACKUP=false
                shift
                ;;
            --no-health)
                CHECK_HEALTH=false
                shift
                ;;
            --help)
                show_help
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log_info "Starting deployment to $DEPLOYMENT_TARGET"
    echo "================================================"
    
    # Run deployment steps
    check_prerequisites
    
    if [ "$CREATE_BACKUP" = true ]; then
        backup_current
    fi
    
    install_dependencies
    setup_database
    
    if [ "$RUN_TESTS" = true ]; then
        run_tests
    fi
    
    if [ "$CHECK_HEALTH" = true ] && [ "$DEPLOYMENT_TARGET" != "docker" ]; then
        check_health
    fi
    
    # Deploy based on target
    case $DEPLOYMENT_TARGET in
        "railway")
            deploy_to_railway
            ;;
        "render")
            deploy_to_render
            ;;
        "docker")
            deploy_to_docker
            ;;
        "vps")
            deploy_to_vps
            ;;
    esac
    
    echo "================================================"
    log_success "🎉 Backend deployment completed successfully!"
    log_info "Target: $DEPLOYMENT_TARGET"
    log_info "Timestamp: $(date)"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi