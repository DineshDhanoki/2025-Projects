#!/bin/bash
# ===================================================================
# MASTER DEPLOYMENT SCRIPT - scripts/deploy-all.sh
# ===================================================================

set -e

echo "🚀 AgentCraft Complete Deployment Script"
echo "========================================"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

show_help() {
    echo "AgentCraft Complete Deployment Script"
    echo ""
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --frontend-only      Deploy only frontend"
    echo "  --backend-only       Deploy only backend"
    echo "  --vercel            Use Vercel for frontend (default)"
    echo "  --netlify           Use Netlify for frontend"
    echo "  --railway           Use Railway for backend (default)"
    echo "  --render            Use Render for backend"
    echo "  --docker            Use Docker for backend"
    echo "  --setup             Run initial setup only"
    echo "  --seed              Seed database with demo data"
    echo "  --help              Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                          # Full deployment (Vercel + Railway)"
    echo "  $0 --netlify --render       # Deploy to Netlify + Render"
    echo "  $0 --frontend-only          # Deploy only frontend"
    echo "  $0 --setup --seed           # Setup and seed data"
}

setup_project() {
    log_info "Setting up AgentCraft project..."
    
    # Make scripts executable
    chmod +x scripts/*.sh
    
    # Backend setup
    if [ -d "backend" ]; then
        log_info "Setting up backend..."
        cd backend
        
        if [ ! -f ".env" ]; then
            if [ -f ".env.example" ]; then
                cp .env.example .env
                log_warning "Created .env from template. Please update with your configuration."
            fi
        fi
        
        npm install
        npx prisma generate
        npx prisma db push
        
        cd ..
        log_success "Backend setup completed"
    fi
    
    # Frontend setup
    if [ -d "frontend" ]; then
        log_info "Setting up frontend..."
        cd frontend
        
        if [ ! -f ".env.local" ]; then
            if [ -f ".env.example" ]; then
                cp .env.example .env.local
                log_warning "Created .env.local from template. Please update with your configuration."
            fi
        fi
        
        npm install
        
        cd ..
        log_success "Frontend setup completed"
    fi
    
    log_success "Project setup completed!"
}

seed_database() {
    log_info "Seeding database with demo data..."
    
    if [ -f "scripts/seed-data.js" ]; then
        node scripts/seed-data.js
        log_success "Database seeded successfully"
    else
        log_error "Seed script not found"
        exit 1
    fi
}

deploy_frontend() {
    local platform=$1
    log_info "Deploying frontend to $platform..."
    
    if [ -f "scripts/deploy-frontend.sh" ]; then
        bash scripts/deploy-frontend.sh --$platform
    else
        log_error "Frontend deployment script not found"
        exit 1
    fi
}

deploy_backend() {
    local platform=$1
    log_info "Deploying backend to $platform..."
    
    if [ -f "scripts/deploy-backend.sh" ]; then
        bash scripts/deploy-backend.sh --$platform
    else
        log_error "Backend deployment script not found"
        exit 1
    fi
}

main() {
    local FRONTEND_PLATFORM="vercel"
    local BACKEND_PLATFORM="railway"
    local DEPLOY_FRONTEND=true
    local DEPLOY_BACKEND=true
    local RUN_SETUP=false
    local SEED_DB=false
    
    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --frontend-only)
                DEPLOY_BACKEND=false
                shift
                ;;
            --backend-only)
                DEPLOY_FRONTEND=false
                shift
                ;;
            --vercel)
                FRONTEND_PLATFORM="vercel"
                shift
                ;;
            --netlify)
                FRONTEND_PLATFORM="netlify"
                shift
                ;;
            --railway)
                BACKEND_PLATFORM="railway"
                shift
                ;;
            --render)
                BACKEND_PLATFORM="render"
                shift
                ;;
            --docker)
                BACKEND_PLATFORM="docker"
                shift
                ;;
            --setup)
                RUN_SETUP=true
                shift
                ;;
            --seed)
                SEED_DB=true
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
    
    log_info "Starting AgentCraft deployment..."
    echo "Frontend: $FRONTEND_PLATFORM"
    echo "Backend: $BACKEND_PLATFORM"
    echo "========================================"
    
    if [ "$RUN_SETUP" = true ]; then
        setup_project
    fi
    
    if [ "$SEED_DB" = true ]; then
        seed_database
    fi
    
    if [ "$DEPLOY_BACKEND" = true ]; then
        deploy_backend $BACKEND_PLATFORM
    fi
    
    if [ "$DEPLOY_FRONTEND" = true ]; then
        deploy_frontend $FRONTEND_PLATFORM
    fi
    
    echo "========================================"
    log_success "🎉 AgentCraft deployment completed!"
    
    if [ "$DEPLOY_FRONTEND" = true ] && [ "$DEPLOY_BACKEND" = true ]; then
        echo ""
        log_info "Next steps:"
        echo "1. Update your frontend environment variables with the backend URL"
        echo "2. Test the application thoroughly"
        echo "3. Monitor the deployments for any issues"
        echo ""
        log_info "Happy coding! 🚀"
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

# ===================================================================
# PACKAGE.JSON UPDATE - backend/package.json (add faker dependency)
# ===================================================================

# Add this to your backend/package.json dependencies:
# "@faker-js/faker": "^8.3.1"

# ===================================================================
# IMPROVED SETUP SCRIPT - scripts/setup.sh (Enhanced version)
# ===================================================================

#!/bin/bash

set -e

echo "🛠️  AgentCraft Complete Setup Script"
echo "=================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2 | cut -d'.' -f1)
        if [ "$NODE_VERSION" -ge 18 ]; then
            log_success "Node.js $(node --version) detected"
        else
            log_error "Node.js 18+ required. Current: $(node --version)"
            exit 1
        fi
    else
        log_error "Node.js not found. Please install Node.js 18+"
        exit 1
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        log_success "npm $(npm --version) detected"
    else
        log_error "npm not found"
        exit 1
    fi
    
    # Check Git
    if command -v git &> /dev/null; then
        log_success "Git $(git --version | cut -d' ' -f3) detected"
    else
        log_warning "Git not found. Some features may not work."
    fi
    
    # Check available ports
    if lsof -Pi :3000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Port 3000 is in use (Frontend)"
    fi
    
    if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
        log_warning "Port 5000 is in use (Backend)"
    fi
}

install_ollama() {
    log_info "Checking Ollama installation..."
    
    if command -v ollama &> /dev/null; then
        log_success "Ollama is already installed"
    else
        log_info "Installing Ollama..."
        
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS
            if command -v brew &> /dev/null; then
                brew install ollama
            else
                curl -fsSL https://ollama.ai/install.sh | sh
            fi
        elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
            # Linux
            curl -fsSL https://ollama.ai/install.sh | sh
        else
            log_warning "Please install Ollama manually from https://ollama.ai"
            return
        fi
        
        log_success "Ollama installed successfully"
    fi
    
    # Start Ollama service
    log_info "Starting Ollama service..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ollama serve &
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        sudo systemctl start ollama 2>/dev/null || ollama serve &
    fi
    
    sleep 5
    
    # Pull default model
    log_info "Pulling Mistral model..."
    if ollama pull mistral; then
        log_success "Mistral model downloaded"
    else
        log_warning "Failed to download Mistral model. You can do this later with 'ollama pull mistral'"
    fi
}

setup_chromadb() {
    log_info "Setting up ChromaDB..."
    
    if command -v docker &> /dev/null; then
        log_info "Starting ChromaDB with Docker..."
        docker run -d -p 8000:8000 chromadb/chroma:latest
        log_success "ChromaDB started on port 8000"
    elif command -v python3 &> /dev/null; then
        log_info "Installing ChromaDB with pip..."
        pip3 install chromadb
        log_success "ChromaDB installed. Start it with 'chroma run --host localhost --port 8000'"
    else
        log_warning "Neither Docker nor Python3 found. Please install ChromaDB manually"
        log_info "Visit: https://docs.trychroma.com/getting-started"
    fi
}

setup_backend() {
    log_info "Setting up backend..."
    
    cd backend
    
    # Create environment file
    if [ ! -f ".env" ]; then
        cp .env.example .env
        log_success "Created .env file"
        
        # Generate JWT secret
        JWT_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "your-super-secret-jwt-key-$(date +%s)")
        sed -i.bak "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/" .env
        rm .env.bak 2>/dev/null || true
        
        log_success "Generated JWT secret"
    fi
    
    # Install dependencies
    log_info "Installing backend dependencies..."
    npm install
    
    # Add faker for seeding
    npm install --save-dev @faker-js/faker
    
    # Setup database
    log_info "Setting up database..."
    npx prisma generate
    npx prisma db push
    
    # Create logs directory
    mkdir -p logs
    
    cd ..
    log_success "Backend setup completed"
}

setup_frontend() {
    log_info "Setting up frontend..."
    
    cd frontend
    
    # Create environment file
    if [ ! -f ".env.local" ]; then
        cp .env.example .env.local
        log_success "Created .env.local file"
        
        # Generate NextAuth secret
        NEXTAUTH_SECRET=$(openssl rand -hex 32 2>/dev/null || echo "your-nextauth-secret-$(date +%s)")
        sed -i.bak "s/your-nextauth-secret/$NEXTAUTH_SECRET/" .env.local
        rm .env.local.bak 2>/dev/null || true
        
        log_success "Generated NextAuth secret"
    fi
    
    # Install dependencies
    log_info "Installing frontend dependencies..."
    npm install
    
    cd ..
    log_success "Frontend setup completed"
}

setup_scripts() {
    log_info "Setting up deployment scripts..."
    
    # Make all scripts executable
    chmod +x scripts/*.sh
    
    log_success "Scripts are now executable"
}

create_sample_data() {
    log_info "Creating sample data..."
    
    if [ -f "scripts/seed-data.js" ]; then
        node scripts/seed-data.js minimal
        log_success "Sample data created"
    else
        log_warning "Seed script not found. Run 'node scripts/seed-data.js' later to create sample data"
    fi
}

show_completion_info() {
    echo ""
    echo "🎉 AgentCraft setup completed successfully!"
    echo "========================================"
    echo ""
    log_info "To start the application:"
    echo ""
    echo "  Backend (Terminal 1):"
    echo "  cd backend && npm run dev"
    echo ""
    echo "  Frontend (Terminal 2):"
    echo "  cd frontend && npm run