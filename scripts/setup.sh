// ===================================================================
// SETUP SCRIPT - scripts/setup.sh
// ===================================================================

#!/bin/bash

echo "🚀 Setting up AgentCraft Backend..."

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 18+ first."
    exit 1
fi

# Check if Ollama is installed
if ! command -v ollama &> /dev/null; then
    echo "❌ Ollama is not installed. Please install Ollama first."
    echo "Visit: https://ollama.ai/download"
    exit 1
fi

echo "✅ Prerequisites check passed"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Setup environment file
if [ ! -f .env ]; then
    echo "📝 Creating environment file..."
    cp .env.example .env
    echo "⚠️  Please edit .env file with your configuration"
fi

# Generate Prisma client
echo "🔧 Setting up database..."
npx prisma generate

# Push database schema
npx prisma db push

# Seed database with sample data
echo "🌱 Seeding database..."
node prisma/seed.js

# Check Ollama service
echo "🤖 Checking Ollama service..."
if curl -s http://localhost:11434/api/tags > /dev/null; then
    echo "✅ Ollama is running"
    
    # Pull default model if not exists
    if ! ollama list | grep -q "mistral"; then
        echo "📥 Pulling Mistral model..."
        ollama pull mistral
    fi
else
    echo "⚠️  Ollama is not running. Please start it:"
    echo "   ollama serve"
fi

echo ""
echo "🎉 Setup completed!"
echo ""
echo "To start the development server:"
echo "   npm run dev"
echo ""
echo "The API will be available at: http://localhost:5000"
echo "Health check: http://localhost:5000/api/health"