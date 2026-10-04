#!/bin/bash

echo "🔧 Setting up Local LLM Native (GPU-Accelerated) Environment"

# Navigate to project root
cd "$(dirname "$0")/.."

# Check prerequisites
echo "📋 Checking prerequisites..."

if ! command -v brew > /dev/null 2>&1; then
    echo "❌ Homebrew is not installed."
    echo "   Install it from https://brew.sh then re-run this script."
    exit 1
fi
echo "✅ Homebrew: $(brew --version | head -1)"

# Install Ollama natively (not the Docker image) if missing
if ! command -v ollama > /dev/null 2>&1; then
    echo "📥 Installing Ollama natively via Homebrew..."
    brew install ollama
else
    echo "✅ Ollama already installed: $(ollama --version 2>&1 | head -1)"
fi

# Create necessary directories (parity with the Docker setup's layout)
echo "📁 Creating project directories..."
mkdir -p logs config

# Make scripts executable
echo "🔐 Making scripts executable..."
chmod +x scripts/*.sh

echo ""
echo "✅ Native environment setup complete!"
echo ""
echo "⚠️  Why native instead of Docker:"
echo "   Docker Desktop on macOS runs containers inside an isolated Linux VM"
echo "   that cannot reach the Mac's GPU. A Dockerized Ollama on Apple"
echo "   Silicon is therefore CPU-only. Measured on an M4 Pro: native"
echo "   (Metal GPU) is ~3-4x faster than the Docker container, cold or"
echo "   warm, on identical prompts (see README for the numbers)."
echo ""
echo "⚠️  Port conflict: both native Ollama and the Docker container bind"
echo "   11434. start-native.sh will stop the Docker container"
echo "   ('llama-local') automatically if it's running, since both can't"
echo "   listen on the same port. 'docker start llama-local' brings the"
echo "   Docker path back any time."
echo ""
echo "🚀 Ready to start development:"
echo ""
echo "1. Start local LLM (native):"
echo "   ./scripts/start-native.sh"
echo ""
echo "2. Validate setup:"
echo "   ./scripts/validate-native.sh"
echo ""
echo "🌐 API endpoints (same as the Docker path - no app config changes needed):"
echo "   - LLM API: http://localhost:11434"
echo "   - Models: http://localhost:11434/api/tags"
