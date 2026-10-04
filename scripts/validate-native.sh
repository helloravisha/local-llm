#!/bin/bash

echo "🧪 Validating Local LLM Service (Native, GPU-Accelerated)"

LLM_PORT="11434"
LLM_MODEL="llama3.2:3b"

echo "🔧 Validation Configuration:"
echo "  LLM Port: $LLM_PORT"
echo "  LLM Model: $LLM_MODEL"

# Test 1: Service Status Check
echo ""
echo "📋 Test 1: Service Status Check"
echo "----------------------------------------"
if ! brew services list 2>/dev/null | grep -q "^ollama.*started"; then
    echo "❌ Ollama service is not running"
    echo "🚀 Start it first with: ./scripts/start-native.sh"
    exit 1
else
    echo "✅ Ollama service is running"
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
    echo "📋 Check logs with: brew services info ollama"
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

# Test 4: GPU (Metal) Acceleration Check - the whole point of the native path
echo ""
echo "📋 Test 4: GPU Acceleration Check"
echo "----------------------------------------"
curl -s "http://localhost:$LLM_PORT/api/generate" -d "{\"model\":\"$LLM_MODEL\",\"prompt\":\"hi\",\"stream\":false}" > /dev/null
PS_JSON=$(curl -s "http://localhost:$LLM_PORT/api/ps")
VRAM=$(echo "$PS_JSON" | python3 -c "import json,sys; m=json.load(sys.stdin).get('models',[]); print(m[0].get('size_vram',0) if m else 0)" 2>/dev/null || echo 0)
if [ "$VRAM" != "0" ] && [ -n "$VRAM" ]; then
    echo "✅ Running on GPU - size_vram=$VRAM bytes"
else
    echo "❌ size_vram=0 - model is running on CPU, not GPU"
    echo "   This defeats the point of the native setup. On Apple Silicon this"
    echo "   should never be 0 - check for a competing process holding the GPU,"
    echo "   or that this isn't accidentally a Docker/VM-hosted ollama on :$LLM_PORT."
fi

# Test 5: Basic Generation + Timing
echo ""
echo "📋 Test 5: Generation + Timing Test"
echo "----------------------------------------"
GEN_RAW=$(curl -s -X POST "http://localhost:$LLM_PORT/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "'$LLM_MODEL'", "prompt": "Hello, what is 2+2?", "stream": false}')
GEN_TEST=$(echo "$GEN_RAW" | jq -r '.response // "No response"')
TOTAL_MS=$(echo "$GEN_RAW" | python3 -c "import json,sys; print(round(json.load(sys.stdin).get('total_duration',0)/1e6,1))" 2>/dev/null || echo "?")

if [ "$GEN_TEST" != "No response" ]; then
    echo "✅ Generation working (total_duration: ${TOTAL_MS}ms)"
    echo "📦 Response: $GEN_TEST"
else
    echo "❌ Generation failed"
    echo "📦 Response: $GEN_TEST"
fi

# Test 6: Streaming Test
echo ""
echo "📋 Test 6: Streaming Test"
echo "----------------------------------------"
STREAM_TEST=$(curl -s -X POST "http://localhost:$LLM_PORT/api/generate" \
  -H "Content-Type: application/json" \
  -d '{"model": "'$LLM_MODEL'", "prompt": "Explain streaming", "stream": true}' | head -c 100)

if [ ! -z "$STREAM_TEST" ]; then
    echo "✅ Streaming working"
else
    echo "❌ Streaming failed"
fi

echo ""
echo "🎯 Validation Summary"
echo "=================================="
echo "✅ Validation complete!"
echo "🌐 LLM Service: http://localhost:$LLM_PORT"
echo ""
echo "📋 Test your API endpoints:"
echo "  curl -X POST http://localhost:$LLM_PORT/api/generate -H 'Content-Type: application/json' -d '{\"model\": \"llama3.2:3b\", \"prompt\": \"Hello!\", \"stream\": false}'"
echo ""
echo "📋 List available models:"
echo "  curl http://localhost:$LLM_PORT/api/tags"
echo ""
echo "🎯 Your LLM service is ready for development!"
