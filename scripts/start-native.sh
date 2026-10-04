#!/bin/bash

echo "🚀 Starting Local LLM Gateway (Native, GPU-Accelerated)"

# Navigate to project root
cd "$(dirname "$0")/.."

# Configuration (same port as the Docker path on purpose - no app config changes needed)
LLM_PORT="11434"
LLM_MODEL="llama3.2:3b"
DOCKER_CONTAINER="llama-local"
LOGS_DIR="./logs"

echo "🔧 Configuration:"
echo "  Port: $LLM_PORT"
echo "  Model: $LLM_MODEL"
echo "  Logs: $LOGS_DIR"

mkdir -p "$LOGS_DIR"

if ! command -v ollama > /dev/null 2>&1; then
    echo "❌ Ollama is not installed natively. Run ./scripts/setup-native.sh first."
    exit 1
fi

# Free the port if the Docker path is currently holding it - both bind 11434,
# so only one can run at a time. 'docker start llama-local' reverts this.
if command -v docker > /dev/null 2>&1 && docker ps --filter "name=$DOCKER_CONTAINER" --format "{{.Names}}" | grep -q "$DOCKER_CONTAINER"; then
    echo "🛑 Docker container '$DOCKER_CONTAINER' is running and holds port $LLM_PORT - stopping it (not removing; 'docker start $DOCKER_CONTAINER' brings it back)..."
    docker stop "$DOCKER_CONTAINER" > /dev/null
fi

# Performance env vars for the native service (mirrors the Docker setup's
# OLLAMA_NUM_PARALLEL/OLLAMA_MAX_LOADED_MODELS, plus the flash-attention +
# quantized KV cache flags Homebrew's own ollama formula recommends for
# better throughput). launchctl setenv makes these visible to the launchd
# service that 'brew services' manages.
echo "⚙️  Applying performance env vars for the launchd service..."
launchctl setenv OLLAMA_NUM_PARALLEL 2
launchctl setenv OLLAMA_MAX_LOADED_MODELS 3
launchctl setenv OLLAMA_FLASH_ATTENTION 1
launchctl setenv OLLAMA_KV_CACHE_TYPE q8_0

# Start (or restart to pick up the env vars above) as a persistent service -
# survives reboots/logouts, unlike a plain backgrounded 'ollama serve'.
echo "🚀 Starting Ollama as a background service..."
brew services restart ollama > /dev/null

# Wait for Ollama to be ready
echo "⏳ Waiting for LLM service to be ready..."
for i in $(seq 1 15); do
    if curl -f "http://localhost:$LLM_PORT/api/tags" > /dev/null 2>&1; then
        echo "✅ LLM service is ready after ${i} attempt(s)"
        echo "🌐 LLM available at: http://localhost:$LLM_PORT"

        echo "📥 Pulling model $LLM_MODEL..."
        ollama pull "$LLM_MODEL"

        echo ""
        echo "🔍 Confirming GPU (Metal) acceleration..."
        curl -s "http://localhost:$LLM_PORT/api/generate" -d "{\"model\":\"$LLM_MODEL\",\"prompt\":\"hi\",\"stream\":false}" > /dev/null
        VRAM=$(curl -s "http://localhost:$LLM_PORT/api/ps" | python3 -c "import json,sys; m=json.load(sys.stdin).get('models',[]); print(m[0].get('size_vram',0) if m else 0)" 2>/dev/null || echo 0)
        if [ "$VRAM" != "0" ] && [ -n "$VRAM" ]; then
            echo "✅ GPU acceleration active (size_vram=$VRAM bytes resident on GPU)"
        else
            echo "⚠️  size_vram is 0 - model is running on CPU, not GPU. Expected on Apple"
            echo "   Silicon; if you're on one and seeing this, check 'ollama ps' and that"
            echo "   no other process/VM is intercepting the Metal device."
        fi

        echo ""
        echo "📊 Service Status:"
        brew services list | grep ollama
        exit 0
    fi
    echo "⏳ Attempt $i/15 - LLM not ready yet..."
    sleep 2
done

echo "❌ LLM service failed to start after 15 attempts"
echo "📋 Check logs with: brew services info ollama ; tail -f /opt/homebrew/var/log/ollama.log 2>/dev/null"
exit 1
