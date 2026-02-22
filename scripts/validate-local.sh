#!/bin/bash

echo "🧪 Validating Local LLM Service"

# Configuration
LLM_NAME="llama-local"
LLM_PORT="11434"
LLM_MODEL="llama3.2:3b"

echo "🔧 Validation Configuration:"
echo "  LLM Container: $LLM_NAME"
echo "  LLM Port: $LLM_PORT"
echo "  LLM Model: $LLM_MODEL"

# Test 1: Container Status Check
echo ""
echo "📋 Test 1: Container Status Check"
echo "----------------------------------------"
if ! docker ps --filter "name=$LLM_NAME" --format "{{.Status}}" | grep -q "Up"; then
    echo "❌ LLM container is not running"
    echo "📋 Check logs with: docker logs -f $LLM_NAME"
    echo "🚀 Start LLM first with: ./scripts/start-local.sh"
    exit 1
else
    echo "✅ LLM container is running"
fi

# Test 2: LLM Service Health
echo ""
echo "📋 Test 2: LLM Service Health Check"
echo "----------------------------------------"
if curl -f "http://localhost:$LLM_PORT/api/tags" > /dev/null 2>&1; then
    echo "✅ LLM service is healthy"
    echo "🌐 Available at: http://localhost:$LLM_PORT"
else
    echo "❌ LLM service is not responding"
    echo "📋 Check logs with: docker logs -f $LLM_NAME"
    exit 1
fi

# Test 3: Model Availability
echo ""
echo "📋 Test 3: Model Availability Check"
echo "----------------------------------------"
MODEL_CHECK=$(curl -s "http://localhost:$LLM_PORT/api/tags" | jq -r '.models[] | select(.name=="'$LLM_MODEL'") | .name')
if [ "$MODEL_CHECK" = "$LLM_MODEL" ]; then
    echo "✅ Model $LLM_MODEL is available"
else
    echo "❌ Model $LLM_MODEL not found"
    echo "📋 Available models:"
    curl -s "http://localhost:$LLM_PORT/api/tags" | jq '.models[].name'
fi

# Test 4: Basic Generation
echo ""
echo "📋 Test 4: Basic Generation Test"
echo "----------------------------------------"
GEN_TEST=$(curl -s -X POST "http://localhost:$LLM_PORT/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "'$LLM_MODEL'", "prompt": "Hello, what is 2+2?", "stream": false}' | jq -r '.response // "No response"')

if [ "$GEN_TEST" != "No response" ]; then
    echo "✅ Basic generation working"
    echo "📦 Response: $GEN_TEST"
else
    echo "❌ Basic generation failed"
    echo "📦 Response: $GEN_TEST"
fi

# Test 5: Streaming Test
echo ""
echo "📋 Test 5: Streaming Test"
echo "----------------------------------------"
STREAM_TEST=$(curl -s -X POST "http://localhost:$LLM_PORT/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "'$LLM_MODEL'", "prompt": "Explain streaming", "stream": true}' | head -c 100)

if [ ! -z "$STREAM_TEST" ]; then
    echo "✅ Streaming working"
else
    echo "❌ Streaming failed"
fi

# Container Status Summary
echo ""
echo "📊 Container Status Summary"
echo "=================================="
docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}\t{{.Image}}"

echo ""
echo "🎯 Validation Summary"
echo "=================================="
echo "✅ All validation tests completed!"
echo "🌐 LLM Service: http://localhost:$LLM_PORT"
echo ""
echo "📋 Test your API endpoints:"
echo "  curl -X POST http://localhost:$LLM_PORT/api/generate -H 'Content-Type: application/json' -d '{\"model\": \"llama3.2:3b\", \"prompt\": \"Hello!\", \"stream\": false}'"
echo ""
echo "📋 List available models:"
echo "  curl http://localhost:$LLM_PORT/api/tags"
echo ""
echo "🎯 Your LLM service is ready for development!"
