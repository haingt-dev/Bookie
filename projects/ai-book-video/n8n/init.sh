#!/usr/bin/env bash
# Auto-setup n8n owner account from .env credentials
# Run after `docker compose up`: ./init.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/.env" 2>/dev/null || true

N8N_URL="${N8N_URL:-http://localhost:5678}"
N8N_EMAIL="${N8N_EMAIL:-hai@bookie.dev}"
N8N_PASSWORD="${N8N_PASSWORD:-Bookie123!}"
N8N_FIRST_NAME="${N8N_FIRST_NAME:-Hai}"
N8N_LAST_NAME="${N8N_LAST_NAME:-Nguyen}"

echo "[init] Waiting for n8n at $N8N_URL..."
for i in $(seq 1 30); do
    if curl -sf "$N8N_URL/healthz" > /dev/null 2>&1; then
        echo "[init] n8n is ready."
        break
    fi
    [ "$i" -eq 30 ] && echo "[init] Timeout waiting for n8n" && exit 1
    sleep 2
done

# Check if already set up (try login)
LOGIN=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$N8N_URL/rest/login" \
    -H "Content-Type: application/json" \
    -d "{\"emailOrLdapLoginId\":\"$N8N_EMAIL\",\"password\":\"$N8N_PASSWORD\"}" 2>/dev/null)

if [ "$LOGIN" = "200" ]; then
    echo "[init] Owner already exists ($N8N_EMAIL). Skipping setup."
    exit 0
fi

# Create owner
RESULT=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$N8N_URL/rest/owner/setup" \
    -H "Content-Type: application/json" \
    -d "{\"email\":\"$N8N_EMAIL\",\"firstName\":\"$N8N_FIRST_NAME\",\"lastName\":\"$N8N_LAST_NAME\",\"password\":\"$N8N_PASSWORD\"}")

if [ "$RESULT" = "200" ]; then
    echo "[init] Owner created: $N8N_EMAIL"
else
    echo "[init] Setup returned HTTP $RESULT (may already be configured)"
fi
