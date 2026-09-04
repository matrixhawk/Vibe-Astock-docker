#!/usr/bin/env sh
set -eu

: "${IMAGE_NAME:=vibe-astock:local}"
: "${HOST_PORT:=5898}"
: "${UVICORN_WORKERS:=1}"
: "${VR_API_KEY:=}"
: "${VR_ALLOW_ORIGINS:=*}"
: "${VIBE_ALLOW_HOSTS:=}"
: "${VIBE_MARKET_PROXY:=}"
: "${VIBE_MARKET_DIRECT:=}"
: "${MIMO_API_KEY:=}"
: "${MIMO_BASE_URL:=}"
: "${MIMO_MODEL:=}"
: "${IWENCAI_API_KEY:=}"
: "${MIMO_CONFIG_DIR:=${HOME:-}/.config/mimo}"

set -- run --rm \
  --name vibe-astock \
  -p "$HOST_PORT:8080" \
  -e HOME=/data \
  -e "UVICORN_WORKERS=$UVICORN_WORKERS" \
  -e "VR_API_KEY=$VR_API_KEY" \
  -e "VR_ALLOW_ORIGINS=$VR_ALLOW_ORIGINS" \
  -e "VIBE_ALLOW_HOSTS=$VIBE_ALLOW_HOSTS" \
  -e "VIBE_MARKET_PROXY=$VIBE_MARKET_PROXY" \
  -e "VIBE_MARKET_DIRECT=$VIBE_MARKET_DIRECT" \
  -e "MIMO_API_KEY=$MIMO_API_KEY" \
  -e "MIMO_BASE_URL=$MIMO_BASE_URL" \
  -e "MIMO_MODEL=$MIMO_MODEL" \
  -e "IWENCAI_API_KEY=$IWENCAI_API_KEY" \
  -v vibe_astock_data:/data

if [ -d "$MIMO_CONFIG_DIR" ]; then
  set -- "$@" --mount "type=bind,source=$MIMO_CONFIG_DIR,target=/data/.config/mimo,readonly"
fi

set -- "$@" "$IMAGE_NAME"
docker "$@"
