#!/usr/bin/env bash
# vixtts-server.sh — Manage viXTTS TTS server (Podman + GPU)
#
# Usage:
#   ./scripts/vixtts-server.sh setup        # Pull image + download model + prepare voice ref
#   ./scripts/vixtts-server.sh start        # Start server (port 8020)
#   ./scripts/vixtts-server.sh stop         # Stop server
#   ./scripts/vixtts-server.sh status       # Check status
#   ./scripts/vixtts-server.sh logs         # Tail server logs
#   ./scripts/vixtts-server.sh prepare-ref  # Re-process voice reference audio
#
# Prerequisites:
#   - Podman with NVIDIA Container Toolkit + CDI configured
#   - NVIDIA GPU with >=4GB VRAM
#   - ffmpeg (for reference audio processing)
#
# Model: viXTTS — XTTS-v2 fine-tuned for Vietnamese (~1.9GB)
# Source: https://huggingface.co/capleaf/viXTTS

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# --- Configuration ---
VIXTTS_DIR="${VIXTTS_DIR:-$HOME/.local/share/vixtts}"
IMAGE_NAME="${VIXTTS_IMAGE:-docker.io/daswer123/xtts-api-server:latest}"
CONTAINER_NAME="${VIXTTS_CONTAINER:-vixtts-server}"
API_PORT="${VIXTTS_API_PORT:-8020}"

MODEL_REPO="capleaf/viXTTS"
HF_BASE_URL="https://huggingface.co/$MODEL_REPO/resolve/main"

SPEAKER_NAME="bookie-hai"
VOICE_REF_SRC="$PROJECT_DIR/assets/brand/voice-reference/reference.wav"
VOICE_REF_START="${VOICE_REF_START:-5}"
VOICE_REF_DURATION="${VOICE_REF_DURATION:-8}"

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

log()  { echo -e "${GREEN}[vixtts]${NC} $*"; }
warn() { echo -e "${YELLOW}[vixtts]${NC} $*"; }
err()  { echo -e "${RED}[vixtts]${NC} $*" >&2; }

# --- Commands ---

cmd_setup() {
  log "Setting up viXTTS server..."

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

  if ! command -v ffmpeg &>/dev/null; then
    err "ffmpeg not found. Required for reference audio processing."
    exit 1
  fi

  # 2. Pull image
  log "Pulling xtts-api-server image..."
  podman pull "$IMAGE_NAME"

  # 3. Download viXTTS model
  mkdir -p "$VIXTTS_DIR/models/vixtts" "$VIXTTS_DIR/speakers" "$VIXTTS_DIR/output"

  local model_files=("model.pth" "config.json" "vocab.json")
  for f in "${model_files[@]}"; do
    if [[ -f "$VIXTTS_DIR/models/vixtts/$f" ]]; then
      log "Already downloaded: $f"
    else
      log "Downloading $f from $MODEL_REPO..."
      curl -L --progress-bar \
        "$HF_BASE_URL/$f" \
        -o "$VIXTTS_DIR/models/vixtts/$f"
    fi
  done

  # 4. Prepare voice reference
  cmd_prepare_ref

  log "Setup complete!"
  echo ""
  echo -e "  Start server:  ${BOLD}$0 start${NC}"
  echo -e "  Check status:  ${BOLD}$0 status${NC}"
}

cmd_add_speaker() {
  local name="${1:-}"
  local source="${2:-}"
  local start="${3:-0}"
  local duration="${4:-15}"

  if [[ -z "$name" ]] || [[ -z "$source" ]]; then
    err "Usage: $0 add-speaker <name> <audio-source> [start_sec] [duration_sec]"
    err "  audio-source: local file path or YouTube URL (requires yt-dlp)"
    exit 1
  fi

  if ! command -v ffmpeg &>/dev/null; then
    err "ffmpeg not found."
    exit 1
  fi

  mkdir -p "$VIXTTS_DIR/speakers"
  local input_file="$source"

  # If source looks like a URL, download with yt-dlp
  if [[ "$source" =~ ^https?:// ]]; then
    if ! command -v yt-dlp &>/dev/null; then
      err "yt-dlp not found. Install: pip install yt-dlp"
      exit 1
    fi
    local tmp_dir
    tmp_dir=$(mktemp -d)
    log "Downloading audio from URL..."
    yt-dlp -x --audio-format wav -o "$tmp_dir/audio.%(ext)s" "$source"
    input_file="$tmp_dir/audio.wav"
  fi

  if [[ ! -f "$input_file" ]]; then
    err "Audio file not found: $input_file"
    exit 1
  fi

  local output="$VIXTTS_DIR/speakers/$name.wav"

  log "Processing speaker: $name"
  log "  Source: $source"
  log "  Trim: ${start}s offset, ${duration}s duration"
  log "  Resample: 22050Hz mono PCM 16-bit"

  ffmpeg -y \
    -i "$input_file" \
    -ss "$start" \
    -t "$duration" \
    -ar 22050 -ac 1 \
    -acodec pcm_s16le \
    "$output" 2>/dev/null

  # Clean up temp file if downloaded
  if [[ "$source" =~ ^https?:// ]] && [[ -n "${tmp_dir:-}" ]]; then
    rm -rf "$tmp_dir"
  fi

  local actual_duration
  actual_duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$output" 2>/dev/null | cut -d. -f1)
  log "Speaker ready: $output (${actual_duration}s, 22050Hz mono)"
  warn "Restart server to load new speaker: $0 stop && $0 start"
}

cmd_prepare_ref() {
  if [[ ! -f "$VOICE_REF_SRC" ]]; then
    err "Voice reference not found: $VOICE_REF_SRC"
    err "Record 1-3 min giong doc tu nhien, save as WAV tai path tren."
    exit 1
  fi

  if ! command -v ffmpeg &>/dev/null; then
    err "ffmpeg not found."
    exit 1
  fi

  mkdir -p "$VIXTTS_DIR/speakers"
  local output="$VIXTTS_DIR/speakers/$SPEAKER_NAME.wav"

  log "Processing voice reference..."
  log "  Source: $VOICE_REF_SRC"
  log "  Trim: ${VOICE_REF_START}s offset, ${VOICE_REF_DURATION}s duration"
  log "  Resample: 22050Hz mono"

  ffmpeg -y \
    -i "$VOICE_REF_SRC" \
    -ss "$VOICE_REF_START" \
    -t "$VOICE_REF_DURATION" \
    -ar 22050 -ac 1 \
    -acodec pcm_s16le \
    "$output" 2>/dev/null

  local duration
  duration=$(ffprobe -v quiet -show_entries format=duration -of csv=p=0 "$output" 2>/dev/null | cut -d. -f1)
  log "Reference ready: $output (${duration}s, 22050Hz mono)"
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
    if [[ ! -f "$VIXTTS_DIR/models/vixtts/model.pth" ]]; then
      err "Model not found. Run setup first: $0 setup"
      exit 1
    fi

    # Check speaker exists
    if [[ ! -f "$VIXTTS_DIR/speakers/$SPEAKER_NAME.wav" ]]; then
      err "Speaker reference not found. Run: $0 prepare-ref"
      exit 1
    fi

    log "Starting viXTTS server on port $API_PORT..."
    podman run -d \
      --name "$CONTAINER_NAME" \
      --device nvidia.com/gpu=all \
      --security-opt=label=disable \
      -e COQUI_TOS_AGREED=1 \
      -e NUMBA_CACHE_DIR=/tmp/numba_cache \
      -v "$VIXTTS_DIR/models:/data/models" \
      -v "$VIXTTS_DIR/speakers:/data/speakers" \
      -v "$VIXTTS_DIR/output:/data/output" \
      -v "$VIXTTS_DIR/patch-vietnamese.sh:/data/patch-vietnamese.sh:ro" \
      -p "$API_PORT:8020" \
      "$IMAGE_NAME" \
      /bin/bash -c "
        bash /data/patch-vietnamese.sh
        echo y | python3 -m xtts_api_server -hs 0.0.0.0 -p 8020 -ms local -mf /data/models -v vixtts -sf /data/speakers -o /data/output -d cuda
      "
  fi

  # Wait for server to be ready
  log "Waiting for server to load model..."
  local max_wait=120
  local waited=0
  while [[ $waited -lt $max_wait ]]; do
    if curl -s "http://127.0.0.1:$API_PORT/speakers" 2>/dev/null | grep -q "\["; then
      echo ""
      log "Server ready at http://127.0.0.1:$API_PORT"
      log "API docs: http://127.0.0.1:$API_PORT/docs"
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
      local speakers
      speakers=$(curl -s "http://127.0.0.1:$API_PORT/speakers" 2>/dev/null || echo "unreachable")
      local gpu_info
      gpu_info=$(podman exec "$CONTAINER_NAME" nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader 2>/dev/null || echo "unknown")
      echo -e "${GREEN}Running${NC} on port $API_PORT"
      echo -e "  Speakers: $speakers"
      echo -e "  GPU:      $gpu_info"
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
  setup)       cmd_setup ;;
  start)       cmd_start ;;
  stop)        cmd_stop ;;
  status)      cmd_status ;;
  logs)        cmd_logs ;;
  prepare-ref) cmd_prepare_ref ;;
  add-speaker) shift; cmd_add_speaker "$@" ;;
  *)
    echo "Usage: $0 {setup|start|stop|status|logs|prepare-ref|add-speaker}"
    echo ""
    echo "Commands:"
    echo "  setup        Pull image, download viXTTS model, prepare voice ref (run once)"
    echo "  start        Start the TTS API server"
    echo "  stop         Stop the server"
    echo "  status       Check server status and GPU usage"
    echo "  logs         Tail server logs"
    echo "  prepare-ref  Re-process voice reference audio"
    echo "  add-speaker  Add a new speaker from local file or YouTube URL"
    echo ""
    echo "Add speaker:"
    echo "  $0 add-speaker <name> <audio-source> [start_sec] [duration_sec]"
    echo "  audio-source: local file path or YouTube URL (requires yt-dlp)"
    echo "  start_sec:    trim offset (default: 0)"
    echo "  duration_sec: trim duration (default: 15)"
    echo ""
    echo "Environment:"
    echo "  VIXTTS_DIR           Data directory (default: ~/.local/share/vixtts)"
    echo "  VIXTTS_API_PORT      API port (default: 8020)"
    echo "  VOICE_REF_START      Trim start in seconds (default: 5)"
    echo "  VOICE_REF_DURATION   Trim duration in seconds (default: 8)"
    exit 1
    ;;
esac
