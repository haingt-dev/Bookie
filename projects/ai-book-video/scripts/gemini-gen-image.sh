#!/usr/bin/env bash
# gemini-gen-image.sh — Generate images via Gemini API from text prompts
# Modes:
#   Single: --prompt "TEXT" --output file.png
#   Batch:  --file prompts.txt --output-dir ./dir/
#
# Env: GEMINI_API_KEY (required), GEMINI_MODEL (optional override)

set -euo pipefail

# --- Defaults ---
GEMINI_API_BASE="https://generativelanguage.googleapis.com/v1beta/models"
DEFAULT_MODEL="gemini-3.1-flash-image-preview"
MAX_RETRIES=3
RETRY_DELAY=2

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# --- Parse Arguments ---
PROMPT=""
BATCH_FILE=""
OUTPUT=""
OUTPUT_DIR="."
ASPECT="16:9"
SIZE="2K"
MODEL=""
PREFIX=""
FORCE=0

usage() {
  cat <<'EOF'
Usage:
  gemini-gen-image.sh --prompt "TEXT" --output file.png [OPTIONS]
  gemini-gen-image.sh --file prompts.txt --output-dir ./dir/ [OPTIONS]

Options:
  --prompt TEXT       Single prompt text
  --file PATH         Batch prompt file (format: "NUM | prompt text" per line)
  --output PATH       Output file (single mode)
  --output-dir DIR    Output directory (batch mode, default: .)
  --aspect RATIO      Aspect ratio (default: 16:9)
  --size SIZE         Image size (default: 2K)
  --model MODEL       Gemini model override
  --prefix TEXT       Filename prefix for batch mode
  --force             Overwrite existing files
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --prompt)   PROMPT="$2"; shift 2 ;;
    --file)     BATCH_FILE="$2"; shift 2 ;;
    --output)   OUTPUT="$2"; shift 2 ;;
    --output-dir) OUTPUT_DIR="$2"; shift 2 ;;
    --aspect)   ASPECT="$2"; shift 2 ;;
    --size)     SIZE="$2"; shift 2 ;;
    --model)    MODEL="$2"; shift 2 ;;
    --prefix)   PREFIX="$2"; shift 2 ;;
    --force)    FORCE=1; shift ;;
    -h|--help)  usage ;;
    *)          echo -e "${RED}Unknown option: $1${NC}"; usage ;;
  esac
done

# --- Load API Key ---
# Priority: env > local .env > global ~/.config/gemini/.env
load_env() {
  local env_file="$1"
  if [[ -f "$env_file" ]]; then
    set -a
    # shellcheck disable=SC1090
    source "$env_file"
    set +a
  fi
}

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  load_env ".env"
fi
if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  load_env "$HOME/.config/gemini/.env"
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo -e "${RED}Error: GEMINI_API_KEY not set. Set via env, .env, or ~/.config/gemini/.env${NC}"
  exit 1
fi

# --- Resolve Model ---
# Priority: --model flag > GEMINI_MODEL env > default
if [[ -z "$MODEL" ]]; then
  MODEL="${GEMINI_MODEL:-$DEFAULT_MODEL}"
fi

# --- Validate Mode ---
if [[ -n "$PROMPT" && -n "$BATCH_FILE" ]]; then
  echo -e "${RED}Error: Cannot use both --prompt and --file${NC}"
  exit 1
fi
if [[ -z "$PROMPT" && -z "$BATCH_FILE" ]]; then
  echo -e "${RED}Error: Specify --prompt or --file${NC}"
  usage
fi
if [[ -n "$PROMPT" && -z "$OUTPUT" ]]; then
  echo -e "${RED}Error: --output required with --prompt${NC}"
  exit 1
fi

# ============================================================
# Core: generate a single image
# ============================================================
generate_image() {
  local prompt="$1"
  local output="$2"
  local tmp_response
  tmp_response=$(mktemp)

  for attempt in $(seq 1 "$MAX_RETRIES"); do
    local http_code
    http_code=$(curl -s -w '%{http_code}' --max-time 60 -X POST \
      "${GEMINI_API_BASE}/${MODEL}:generateContent?key=${GEMINI_API_KEY}" \
      -H "Content-Type: application/json" \
      -d "$(jq -n --arg prompt "$prompt" --arg size "$SIZE" --arg aspect "$ASPECT" '{
        contents: [{parts: [{text: $prompt}]}],
        generationConfig: {
          responseModalities: ["IMAGE"],
          imageConfig: {aspectRatio: $aspect, imageSize: $size}
        }
      }')" \
      -o "$tmp_response")

    # Check HTTP status
    if [[ "$http_code" != "200" ]]; then
      local error_msg
      error_msg=$(jq -r '.error.message // "Unknown error"' "$tmp_response" 2>/dev/null || echo "HTTP $http_code")
      if [[ $attempt -lt $MAX_RETRIES ]]; then
        echo -e "${YELLOW}  Retry ${attempt}/${MAX_RETRIES}: ${error_msg} (waiting ${RETRY_DELAY}s)...${NC}"
        sleep "$RETRY_DELAY"
        continue
      fi
      echo -e "${RED}  Error: ${error_msg}${NC}"
      rm -f "$tmp_response"
      return 1
    fi

    # Extract base64 image data
    local image_data
    image_data=$(jq -r '.candidates[0].content.parts[] | select(.inlineData) | .inlineData.data' "$tmp_response" 2>/dev/null)

    if [[ -z "$image_data" || "$image_data" == "null" ]]; then
      # Check safety filter block
      local block_reason
      block_reason=$(jq -r '.candidates[0].finishReason // .promptFeedback.blockReason // empty' "$tmp_response" 2>/dev/null)
      if [[ -n "$block_reason" && "$block_reason" != "STOP" ]]; then
        echo -e "${RED}  Blocked: ${block_reason}${NC}"
        rm -f "$tmp_response"
        return 1
      fi

      if [[ $attempt -lt $MAX_RETRIES ]]; then
        echo -e "${YELLOW}  Retry ${attempt}/${MAX_RETRIES}: No image in response (waiting ${RETRY_DELAY}s)...${NC}"
        sleep "$RETRY_DELAY"
        continue
      fi
      echo -e "${RED}  Error: No image data after ${MAX_RETRIES} attempts${NC}"
      rm -f "$tmp_response"
      return 1
    fi

    # Decode base64 → PNG
    echo "$image_data" | base64 -d > "$output"

    if [[ -s "$output" ]]; then
      rm -f "$tmp_response"
      return 0
    fi

    if [[ $attempt -lt $MAX_RETRIES ]]; then
      echo -e "${YELLOW}  Retry ${attempt}/${MAX_RETRIES}: Decoded file empty (waiting ${RETRY_DELAY}s)...${NC}"
      sleep "$RETRY_DELAY"
    fi
  done

  rm -f "$tmp_response"
  return 1
}

# ============================================================
# Single mode
# ============================================================
if [[ -n "$PROMPT" ]]; then
  # Create output directory if needed
  mkdir -p "$(dirname "$OUTPUT")"

  if [[ -f "$OUTPUT" && $FORCE -eq 0 ]]; then
    echo -e "${YELLOW}Skipped: ${OUTPUT} already exists (use --force to overwrite)${NC}"
    exit 0
  fi

  echo -e "${CYAN}Generating image...${NC}"
  echo -e "${CYAN}Model: ${MODEL} | Size: ${SIZE} | Aspect: ${ASPECT}${NC}"

  if generate_image "$PROMPT" "$OUTPUT"; then
    local_size=$(du -h "$OUTPUT" | cut -f1)
    echo -e "${GREEN}Done: ${OUTPUT} (${local_size})${NC}"
  else
    echo -e "${RED}Failed to generate image${NC}"
    exit 1
  fi
  exit 0
fi

# ============================================================
# Batch mode
# ============================================================
if [[ -n "$BATCH_FILE" ]]; then
  if [[ ! -f "$BATCH_FILE" ]]; then
    echo -e "${RED}Error: Batch file not found: ${BATCH_FILE}${NC}"
    exit 1
  fi

  mkdir -p "$OUTPUT_DIR"

  echo -e "${CYAN}Batch generating images...${NC}"
  echo -e "${CYAN}Model: ${MODEL} | Size: ${SIZE} | Aspect: ${ASPECT}${NC}"
  echo ""

  generated=0
  skipped=0
  failed=0
  total=0

  while IFS= read -r line; do
    # Skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Parse: NUM | prompt text
    if [[ "$line" =~ ^([0-9]+)[[:space:]]*\|[[:space:]]*(.+)$ ]]; then
      num="${BASH_REMATCH[1]}"
      prompt_text="${BASH_REMATCH[2]}"
    else
      echo -e "${YELLOW}Skipping malformed line: ${line}${NC}"
      continue
    fi

    total=$((total + 1))
    padded_num=$(printf '%02d' "$((10#$num))")
    output_file="${OUTPUT_DIR}/${PREFIX}${padded_num}.png"

    # Skip if exists (unless --force)
    if [[ -f "$output_file" && $FORCE -eq 0 ]]; then
      echo -e "  ${CYAN}[${padded_num}]${NC} Skipped (exists)"
      skipped=$((skipped + 1))
      continue
    fi

    echo -ne "  ${CYAN}[${padded_num}]${NC} Generating..."

    if generate_image "$prompt_text" "$output_file"; then
      local_size=$(du -h "$output_file" | cut -f1)
      echo -e "\r  ${GREEN}[${padded_num}]${NC} Done (${local_size})"
      generated=$((generated + 1))
    else
      echo -e "\r  ${RED}[${padded_num}]${NC} Failed"
      failed=$((failed + 1))
    fi

    # Rate limit
    sleep 1
  done < "$BATCH_FILE"

  echo ""
  echo -e "${CYAN}Summary:${NC} ${generated} generated, ${skipped} skipped, ${failed} failed (${total} total)"

  if [[ $failed -gt 0 ]]; then
    echo -e "${YELLOW}Tip: Re-run to retry failed images (existing ones will be skipped).${NC}"
    exit 1
  fi

  echo -e "${GREEN}All images ready in ${OUTPUT_DIR}/${NC}"
fi
