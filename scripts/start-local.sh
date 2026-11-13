#!/bin/bash

echo "Starting Local LLM Gateway Development"

# Configuration
LLM_NAME="llama-local"
LLM_PORT="11434"
# Every model to have on this server (all served on the same port, chosen by name per request).
# Keep in line with the Ollama models switched on in the LLM gateway's Model Registry.
LLM_MODELS="llama3.2:3b qwen2.5:7b"
MODELS_DIR="../models"
LOGS_DIR="./logs"
CONFIG_DIR="./config"

echo "🔧 Configuration:"
echo "  Container: $LLM_NAME"
echo "  Port: $LLM_PORT"
echo "  Models: $LLM_MODELS"
echo "  Models: $MODELS_DIR"
echo "  Logs: $LOGS_DIR"
echo "  Config: $CONFIG_DIR"

# Create directories if they don't exist
mkdir -p "$MODELS_DIR" "$LOGS_DIR" "$CONFIG_DIR"

# Stop existing container
echo " Stopping existing container..."
docker stop "$LLM_NAME" 2>/dev/null || true
docker rm "$LLM_NAME" 2>/dev/null || true

# Pull latest Ollama image
echo " Pulling latest Ollama image..."
docker pull ollama/ollama:latest

# Start LLM container
echo "Starting LLM container..."
docker run -d \
  --name "$LLM_NAME" \
  --network llama-network \
  -p "$LLM_PORT:11434" \
  -v "$MODELS_DIR:/root/.ollama" \
  -v "$LOGS_DIR:/app/logs" \
  -v "$CONFIG_DIR:/app/config" \
  --entrypoint sh \
  ollama/ollama:latest \
  -c "exec ollama serve"

# Wait for LLM to be ready
echo " Waiting for LLM service to be ready..."
sleep 45

# Health check
echo "Checking LLM health..."
for i in {1..10}; do
    if curl -f "http://localhost:$LLM_PORT/api/tags" > /dev/null 2>&1; then
        echo " LLM service is ready after ${i} attempts"
        echo " LLM available at: http://localhost:$LLM_PORT"
        
        # Pull models after server is ready (already-downloaded ones are only checked)
        for m in $LLM_MODELS; do
            echo " Pulling model $m..."
            docker exec "$LLM_NAME" ollama pull "$m"
        done

        echo " Models: $LLM_MODELS"
        echo ""
        echo " Container Status:"
        docker ps --filter "name=$LLM_NAME" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"
        exit 0
    fi
    echo " Attempt $i/10 - LLM not ready yet..."
    sleep 5
done

echo " LLM service failed to start after 10 attempts"
echo " Check logs with: docker logs -f $LLM_NAME"
exit 1
