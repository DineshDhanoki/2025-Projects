#!/bin/bash
# ===================================================================
# FRONTEND DEPLOYMENT SCRIPT - scripts/deploy-frontend.sh
# ===================================================================

set -e  # Exit on any error

echo "🚀 Starting AgentCraft Frontend Deployment..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FRONTEND_DIR="frontend"
BUILD_DIR="$FRONTEND_DIR/.next"
VERCEL_PROJECT_NAME="agentcraft"
BACKUP_DIR="backups/frontend-$(date +%Y%m%d-%H%M%S)"

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
    if [ ! -d "$FRONTEND_DIR" ]; then
        log_error "Frontend directory not found. Are you in the project root?"
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
    
    # Check if npm is available
    if ! command -v npm &> /dev/null; then
        log_error "npm is not installed"
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

backup_current() {
    log_info "Creating backup of current deployment..."
    
    if [ -d "$BUILD_DIR" ]; then
        mkdir -p "$BACKUP_DIR"
        cp -r "$BUILD_DIR" "$BACKUP_DIR/"
        log_success "Backup created at $BACKUP_DIR"
    else
        log_warning "No existing build found to backup"
    fi
}

install_dependencies() {
    log_info "Installing frontend dependencies..."
    
    cd "$FRONTEND_DIR"
    
    # Clean install
    if [ -f "package-lock.json" ]; then
        npm ci
    else
        npm install
    fi
    
    log_success "Dependencies installed"
    cd ..
}

run_tests() {
    log_info "Running frontend tests..."
    
    cd "$FRONTEND_DIR"
    
    # Run linting
    if npm run lint:check &> /dev/null; then
        log_success "Linting passed"
    else
        log_warning "Linting issues found, but continuing..."
    fi
    
    # Run tests if available
    if grep -q '"test"' package.json; then
        if npm test -- --passWithNoTests; then
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

build_frontend() {
    log_info "Building frontend for production..."
    
    cd "$FRONTEND_DIR"
    
    # Set production environment
    export NODE_ENV=production
    
    # Build the application
    npm run build
    
    if [ $? -eq 0 ]; then
        log_success "Frontend build completed successfully"
    else
        log_error "Frontend build failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

deploy_to_vercel() {
    log_info "Deploying to Vercel..."
    
    # Check if Vercel CLI is installed
    if ! command -v vercel &> /dev/null; then
        log_warning "Vercel CLI not found. Installing..."
        npm install -g vercel
    fi
    
    cd "$FRONTEND_DIR"
    
    # Deploy to Vercel
    if vercel --prod --yes; then
        log_success "Successfully deployed to Vercel"
        
        # Get deployment URL
        DEPLOYMENT_URL=$(vercel ls --scope=$VERCEL_PROJECT_NAME 2>/dev/null | grep "https://" | head -1 | awk '{print $2}')
        if [ ! -z "$DEPLOYMENT_URL" ]; then
            log_success "Deployment URL: $DEPLOYMENT_URL"
        fi
    else
        log_error "Vercel deployment failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

deploy_to_netlify() {
    log_info "Deploying to Netlify..."
    
    # Check if Netlify CLI is installed
    if ! command -v netlify &> /dev/null; then
        log_warning "Netlify CLI not found. Installing..."
        npm install -g netlify-cli
    fi
    
    cd "$FRONTEND_DIR"
    
    # Deploy to Netlify
    if netlify deploy --prod --dir=.next; then
        log_success "Successfully deployed to Netlify"
    else
        log_error "Netlify deployment failed"
        cd ..
        exit 1
    fi
    
    cd ..
}

deploy_to_static() {
    log_info "Preparing static deployment..."
    
    cd "$FRONTEND_DIR"
    
    # Export static files
    npm run export 2>/dev/null || npm run build
    
    STATIC_DIR="../dist/frontend"
    mkdir -p "$STATIC_DIR"
    
    if [ -d "out" ]; then
        cp -r out/* "$STATIC_DIR/"
        log_success "Static files copied to $STATIC_DIR"
    elif [ -d ".next" ]; then
        cp -r .next/* "$STATIC_DIR/"
        log_success "Build files copied to $STATIC_DIR"
    else
        log_error "No build output found"
        cd ..
        exit 1
    fi
    
    cd ..
}

cleanup() {
    log_info "Cleaning up..."
    
    # Remove old backups (keep last 5)
    if [ -d "backups" ]; then
        cd backups
        ls -t | tail -n +6 | xargs -r rm -rf
        cd ..
        log_success "Old backups cleaned up"
    fi
}

show_help() {
    echo "AgentCraft Frontend Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --vercel     Deploy to Vercel (default)"
    echo "  --netlify    Deploy to Netlify"
    echo "  --static     Build for static hosting"
    echo "  --no-test    Skip running tests"
    echo "  --no-backup  Skip creating backup"
    echo "  --help       Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Deploy to Vercel with all checks"
    echo "  $0 --netlify         # Deploy to Netlify"
    echo "  $0 --static          # Build for static hosting"
    echo "  $0 --no-test         # Skip tests and deploy to Vercel"
}

# Main deployment function
main() {
    local DEPLOYMENT_TARGET="vercel"
    local RUN_TESTS=true
    local CREATE_BACKUP=true
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --vercel)
                DEPLOYMENT_TARGET="vercel"
                shift
                ;;
            --netlify)
                DEPLOYMENT_TARGET="netlify"
                shift
                ;;
            --static)
                DEPLOYMENT_TARGET="static"
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
    
    if [ "$RUN_TESTS" = true ]; then
        run_tests
    fi
    
    build_frontend
    
    # Deploy based on target
    case $DEPLOYMENT_TARGET in
        "vercel")
            deploy_to_vercel
            ;;
        "netlify")
            deploy_to_netlify
            ;;
        "static")
            deploy_to_static
            ;;
    esac
    
    cleanup
    
    echo "================================================"
    log_success "🎉 Frontend deployment completed successfully!"
    log_info "Target: $DEPLOYMENT_TARGET"
    log_info "Timestamp: $(date)"
}

# Check if script is being sourced or executed
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

