#!/usr/bin/env bash
# fish-speech-server.sh — Manage Fish Speech TTS server (Podman + GPU)
#
# Usage:
#   ./scripts/fish-speech-server.sh setup     # Clone repo + build image + download model (1 lần)
#   ./scripts/fish-speech-server.sh start     # Start server container
#   ./scripts/fish-speech-server.sh stop      # Stop server container
#   ./scripts/fish-speech-server.sh status    # Check if running
#   ./scripts/fish-speech-server.sh logs      # Tail server logs
#
# Prerequisites:
#   - Podman with NVIDIA Container Toolkit + CDI configured
#   - NVIDIA GPU with >=8GB VRAM
#
# Model: OpenAudio S1-mini (0.5B params, ~4.9GB VRAM)

set -euo pipefail

# --- Configuration ---
FISH_SPEECH_DIR="${FISH_SPEECH_DIR:-$HOME/Projects/fish-speech}"
FISH_SPEECH_REPO="https://github.com/fishaudio/fish-speech.git"
IMAGE_NAME="${FISH_IMAGE:-localhost/fish-speech-server:cuda}"
CONTAINER_NAME="${FISH_CONTAINER:-fish-speech-server}"
API_PORT="${FISH_API_PORT:-8080}"
MODEL_ID="${FISH_MODEL:-fishaudio/openaudio-s1-mini}"
MODEL_DIR="checkpoints/openaudio-s1-mini"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[fish-speech]${NC} $*"; }
warn() { echo -e "${YELLOW}[fish-speech]${NC} $*"; }
err()  { echo -e "${RED}[fish-speech]${NC} $*" >&2; }

# --- Commands ---

cmd_setup() {
  log "Setting up Fish Speech server..."

  # 1. Check prerequisites
  if ! command -v podman &>/dev/null; then
    err "podman not found. Install podman first."
    exit 1
  fi

  if ! nvidia-ctk cdi list 2>/dev/null | grep -q "nvidia.com/gpu"; then
    err "NVIDIA CDI not configured. Run:"
    err "  sudo dnf install nvidia-container-toolkit"
    err "  sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml"
    exit 1
  fi

  # 2. Clone repo
  if [[ -d "$FISH_SPEECH_DIR/.git" ]]; then
    log "Repo exists at $FISH_SPEECH_DIR, pulling latest..."
    git -C "$FISH_SPEECH_DIR" pull --ff-only 2>/dev/null || warn "Pull failed, using existing version"
  else
    log "Cloning fish-speech repo..."
    git clone "$FISH_SPEECH_REPO" "$FISH_SPEECH_DIR"
  fi

  # 3. Build image
  log "Building server image (this takes a few minutes)..."
  podman build \
    -f "$FISH_SPEECH_DIR/docker/Dockerfile" \
    --build-arg BACKEND=cuda \
    --build-arg CUDA_VER=12.6.0 \
    --build-arg UV_EXTRA=cu126 \
    --target server \
    -t "$IMAGE_NAME" \
    "$FISH_SPEECH_DIR"

  # 4. Download model
  mkdir -p "$FISH_SPEECH_DIR/checkpoints" "$FISH_SPEECH_DIR/references"

  if [[ -f "$FISH_SPEECH_DIR/$MODEL_DIR/model.pth" ]]; then
    log "Model already downloaded at $FISH_SPEECH_DIR/$MODEL_DIR"
  else
    log "Downloading model $MODEL_ID..."
    if [[ -z "${HF_TOKEN:-}" ]]; then
      warn "HF_TOKEN not set. Model is gated — you need a HuggingFace token."
      warn "  1. Accept license at https://huggingface.co/$MODEL_ID"
      warn "  2. Create token at https://huggingface.co/settings/tokens"
      warn "  3. Re-run: HF_TOKEN=hf_xxx $0 setup"
      exit 1
    fi

    podman run --rm \
      -v "$FISH_SPEECH_DIR/checkpoints:/checkpoints" \
      -e HF_TOKEN="$HF_TOKEN" \
      docker.io/python:3.12-slim \
      bash -c "pip install -q 'huggingface_hub>=0.25' && python3 -c \"
from huggingface_hub import snapshot_download
import os
snapshot_download('$MODEL_ID', local_dir='/checkpoints/openaudio-s1-mini', token=os.environ['HF_TOKEN'])
print('Model downloaded successfully!')
\""
  fi

  log "Setup complete!"
  echo ""
  echo -e "  Start server:  ${BOLD}$0 start${NC}"
  echo -e "  Check status:  ${BOLD}$0 status${NC}"
}

cmd_start() {
  # Check if already running
  if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    if [[ "$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)" == "true" ]]; then
      log "Server already running on port $API_PORT"
      return 0
    fi
    log "Starting existing container..."
    podman start "$CONTAINER_NAME"
  else
    # Check image exists
    if ! podman image exists "$IMAGE_NAME" 2>/dev/null; then
      err "Image not found. Run setup first: $0 setup"
      exit 1
    fi

    # Check model exists
    if [[ ! -f "$FISH_SPEECH_DIR/$MODEL_DIR/model.pth" ]]; then
      err "Model not found. Run setup first: $0 setup"
      exit 1
    fi

    log "Starting Fish Speech server on port $API_PORT..."
    podman run -d \
      --name "$CONTAINER_NAME" \
      --device nvidia.com/gpu=all \
      --security-opt=label=disable \
      --userns=keep-id \
      -v "$FISH_SPEECH_DIR/checkpoints:/app/checkpoints" \
      -v "$FISH_SPEECH_DIR/references:/app/references" \
      -p "$API_PORT:8080" \
      "$IMAGE_NAME"
  fi

  # Wait for server to be ready
  log "Waiting for server to load model..."
  local max_wait=120
  local waited=0
  while [[ $waited -lt $max_wait ]]; do
    if curl -s "http://127.0.0.1:$API_PORT/v1/health" 2>/dev/null | grep -q "ok"; then
      echo ""
      log "Server ready at http://127.0.0.1:$API_PORT"
      return 0
    fi
    printf "."
    sleep 2
    waited=$((waited + 2))
  done

  echo ""
  warn "Server not ready after ${max_wait}s. Check logs: $0 logs"
}

cmd_stop() {
  if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    log "Stopping server..."
    podman stop "$CONTAINER_NAME" 2>/dev/null
    podman rm "$CONTAINER_NAME" 2>/dev/null
    log "Server stopped."
  else
    log "Server not running."
  fi
}

cmd_status() {
  if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    local running
    running=$(podman inspect -f '{{.State.Running}}' "$CONTAINER_NAME" 2>/dev/null)
    if [[ "$running" == "true" ]]; then
      local health
      health=$(curl -s "http://127.0.0.1:$API_PORT/v1/health" 2>/dev/null || echo "unreachable")
      local gpu_info
      gpu_info=$(podman exec "$CONTAINER_NAME" nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "unknown")
      echo -e "${GREEN}Running${NC} on port $API_PORT"
      echo -e "  API:  $health"
      echo -e "  GPU:  $gpu_info"
    else
      echo -e "${YELLOW}Stopped${NC} (container exists, use 'start' to resume)"
    fi
  else
    echo -e "${RED}Not running${NC} (use 'start' or 'setup' first)"
  fi
}

cmd_logs() {
  if podman container exists "$CONTAINER_NAME" 2>/dev/null; then
    podman logs -f "$CONTAINER_NAME"
  else
    err "Server not running."
    exit 1
  fi
}

# --- Main ---
case "${1:-}" in
  setup)  cmd_setup ;;
  start)  cmd_start ;;
  stop)   cmd_stop ;;
  status) cmd_status ;;
  logs)   cmd_logs ;;
  *)
    echo "Usage: $0 {setup|start|stop|status|logs}"
    echo ""
    echo "Commands:"
    echo "  setup   Clone repo, build image, download model (run once)"
    echo "  start   Start the TTS API server"
    echo "  stop    Stop the server"
    echo "  status  Check server status and GPU usage"
    echo "  logs    Tail server logs"
    exit 1
    ;;
esac
