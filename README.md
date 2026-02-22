# Local LLM Service

A simple, containerized Llama 3.2 3B service running on Ollama.

## Quick Start

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
│   ├── setup-development.sh
│   ├── start-local.sh
│   └── validate-local.sh
├── models/          # Ollama models storage
├── logs/            # Application logs
└── config/          # Configuration files
```

## Scripts

### setup-development.sh
- Checks Docker installation
- Creates necessary directories
- Sets up Docker network
- Makes scripts executable

### start-local.sh
- Stops existing containers
- Pulls latest Ollama image
- Starts LLM container
- Downloads Llama 3.2 3B model
- Performs health checks

### validate-local.sh
- Tests container status
- Validates API health
- Checks model availability
- Tests text generation
- Tests streaming functionality

## Troubleshooting

### Check Container Status
```bash
docker ps -a --filter "name=llama-local"
```

### View Logs
```bash
docker logs -f llama-local
```

### Restart Service
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
