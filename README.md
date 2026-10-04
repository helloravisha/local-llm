# Local LLM Service

A simple Llama 3.2 3B service running on Ollama - native (GPU-accelerated) on macOS, or containerized via Docker.

## Which setup should I use?

**Native (recommended on macOS / Apple Silicon).** Docker Desktop on macOS runs containers inside an isolated Linux VM that has no access to the Mac's GPU, so a Dockerized Ollama is always CPU-only - even on a machine with a capable GPU sitting right there unused. Measured on an M4 Pro, same model, same exact prompt, forced cold start on both:

| | Docker (CPU) | Native (Metal GPU) | Speedup |
|---|---|---|---|
| Cold - total | 11,480.8ms | 3,290.1ms | **3.5x** |
| Cold - prompt_eval | 7,503.8ms | 1,824.3ms | **4.1x** |
| Cold - eval | 2,102.9ms | 671.9ms | 3.1x |
| Warm - total | 2,243.0ms | 660.5ms | **3.4x** |

Both paths serve the exact same API on the same port (`11434`) - switching requires no changes to any app pointed at `ollama.base-url=http://localhost:11434`.

**Docker (fallback).** Use this if you're not on Apple Silicon, don't want a Homebrew install, or need the containerized isolation for some other reason. It still works, it's just slower on Mac hardware.

## Quick Start - Native (macOS, GPU-accelerated)

### Prerequisites
- Homebrew (https://brew.sh)

### Setup
```bash
git clone <repository-url>
cd local-llm
./scripts/setup-native.sh
```

### Start the LLM Service
```bash
./scripts/start-native.sh
```
This runs Ollama as a persistent background service (via `brew services`, survives reboots/logouts) on port `11434`. If the Docker container is already running on that port, this stops it first (`docker start llama-local` brings it back any time - nothing is removed).

### Validate the Setup
```bash
./scripts/validate-native.sh
```
Includes an explicit GPU check (`size_vram` from `/api/ps`) - if this ever comes back `0` on Apple Silicon, something's wrong; it should never run on CPU there.

## Quick Start - Docker (fallback)

### Prerequisites
- Docker installed on your system

### Setup
```bash
# Clone and setup
git clone <repository-url>
cd local-llm
./scripts/setup-development.sh
```

### Start the LLM Service
```bash
./scripts/start-local.sh
```

### Validate the Setup
```bash
./scripts/validate-local.sh
```

## Usage

### API Endpoints

**Generate Text**
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "prompt": "Hello!", "stream": false}'
```

**Stream Text**
```bash
curl -X POST http://localhost:11434/api/generate \
  -H "Content-Type: application/json" \
  -d '{"model": "llama3.2:3b", "prompt": "Explain AI", "stream": true}'
```

**List Models**
```bash
curl http://localhost:11434/api/tags
```

### Docker Compose (Alternative)
```bash
docker-compose -f docker/docker-compose.local.yml up -d
```

## Configuration

- **Model**: Llama 3.2 3B (llama3.2:3b)
- **Port**: 11434
- **Memory Limit**: 8GB
- **CPU Limit**: 4 cores

## Project Structure
```
local-llm/
├── docker/
│   └── docker-compose.local.yml
├── scripts/
│   ├── setup-native.sh       # Native (GPU) setup - recommended on macOS
│   ├── start-native.sh
│   ├── validate-native.sh
│   ├── setup-development.sh  # Docker fallback
│   ├── start-local.sh
│   └── validate-local.sh
├── models/          # Ollama models storage (Docker path only - native uses ~/.ollama)
├── logs/            # Application logs
└── config/          # Configuration files
```

## Scripts

### Native (GPU-accelerated, macOS)

#### setup-native.sh
- Checks for Homebrew, installs Ollama natively if missing (not the Docker image)
- Creates necessary directories
- Makes scripts executable

#### start-native.sh
- Stops the Docker container if it's holding port 11434 (reversible - `docker start llama-local`)
- Applies performance env vars (`OLLAMA_NUM_PARALLEL`, `OLLAMA_FLASH_ATTENTION`, `OLLAMA_KV_CACHE_TYPE`) via `launchctl setenv`
- Starts Ollama as a persistent `brew services` background service
- Pulls the model, performs health checks, and confirms GPU acceleration is actually active

#### validate-native.sh
- Tests service status, API health, model availability
- **Explicitly checks `size_vram` to confirm GPU (not CPU) is serving requests**
- Tests generation (with timing) and streaming

### Docker (fallback)

#### setup-development.sh
- Checks Docker installation
- Creates necessary directories
- Sets up Docker network
- Makes scripts executable

#### start-local.sh
- Stops existing containers
- Pulls latest Ollama image
- Starts LLM container
- Downloads Llama 3.2 3B model
- Performs health checks

#### validate-local.sh
- Tests container status
- Validates API health
- Checks model availability
- Tests text generation
- Tests streaming functionality

## Troubleshooting

### Native

**Check service status**
```bash
brew services list | grep ollama
```

**View logs**
```bash
brew services info ollama
```

**Restart service**
```bash
brew services restart ollama
```

**GPU not being used (`size_vram: 0` in `/api/ps`)** - this should never happen on Apple Silicon. Check that nothing else (another Ollama instance, a VM) is competing for the Metal device, and that you're actually hitting the native instance and not a leftover Docker container still bound to the same port.

### Docker (fallback)

**Switching back from native** - `start-local.sh` doesn't know about the native service, so if `brew services` still has native Ollama running on port 11434, starting the Docker container will fail to bind the port. Stop native first:
```bash
brew services stop ollama
./scripts/start-local.sh
```

**Check Container Status**
```bash
docker ps -a --filter "name=llama-local"
```

**View Logs**
```bash
docker logs -f llama-local
```

**Restart Service**
```bash
docker stop llama-local && docker rm llama-local
./scripts/start-local.sh
```

## Model Information

- **Name**: llama3.2:3b
- **Size**: ~2GB
- **Parameters**: 3.2 billion
- **Quantization**: Q4_K_M

## API Reference

### Generate Endpoint
- **URL**: `POST /api/generate`
- **Body**:
  ```json
  {
    "model": "llama3.2:3b",
    "prompt": "Your prompt here",
    "stream": false,
    "options": {
      "temperature": 0.7,
      "max_tokens": 1000
    }
  }
  ```

### Tags Endpoint
- **URL**: `GET /api/tags`
- **Returns**: List of available models
