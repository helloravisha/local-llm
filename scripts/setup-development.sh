#!/bin/bash

echo " Setting up Local LLM Development Environment"

# Check prerequisites
echo " Checking prerequisites..."

# Check if Docker is installed
if ! command -v docker > /dev/null 2>&1; then
    echo "Docker is not installed. Please install Docker first."
    exit 1
fi

echo " Prerequisites check passed!"
echo "  Docker: $(docker --version)"

# Navigate to project root
cd "$(dirname "$0")/.."

# Create necessary directories
echo " Creating project directories..."
mkdir -p models logs config

# Make scripts executable
echo "Making scripts executable..."
chmod +x scripts/*.sh

# Create Docker network
echo " Creating Docker network..."
docker network create llama-network 2>/dev/null || true

echo " Development environment setup complete!"
echo ""
echo " Ready to start development:"
echo ""
echo "1. Start local LLM:"
echo "   ./scripts/start-local.sh"
echo ""
echo "2. Validate setup:"
echo "   ./scripts/validate-local.sh"
echo ""
echo "Project structure:"
echo "   local-llm/"
echo "   ├── docker/"
echo "   ├── scripts/"
echo "   ├── models/"
echo "   ├── logs/"
echo "   └── config/"
echo ""
echo "Next steps:"
echo "   1. Run './scripts/start-local.sh' to start LLM"
echo "   2. Test with './scripts/validate-local.sh'"
echo ""
echo " API endpoints:"
echo "   - LLM API: http://localhost:11434"
echo "   - Models: http://localhost:11434/api/tags"
