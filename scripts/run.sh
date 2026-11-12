#!/usr/bin/env sh
set -eu

: "${IMAGE_NAME:=vibe-astock:local}"
: "${HOST_PORT:=5898}"
: "${VRA_LAN:=1}"
: "${VRA_SCHEDULER:=on}"
: "${VRA_API_TOKEN:=}"
: "${VRA_REMOTE:=}"
: "${VRA_ACCESS_TOKEN:=}"
: "${VRA_PUBLIC_URL:=}"
: "${VRA_PROVIDER:=}"
: "${DEEPSEEK_API_KEY:=}"
: "${ZAI_API_KEY:=}"
: "${MOONSHOT_API_KEY:=}"
: "${MIMO_API_KEY:=}"
: "${OPENAI_API_KEY:=}"
: "${DASHSCOPE_API_KEY:=}"
: "${SELFHOSTED_API_KEY:=}"

set -- run --rm \
  --name vibe-astock \
  -p "$HOST_PORT:8080" \
  -e HOME=/data \
  -e VRA_DATA_ROOT=/data/.local \
  -e VRA_UI_PORT=8080 \
  -e VRA_API_PORT=8770 \
  -e VRA_PYTHON=/opt/venv/bin/python \
  -e "VRA_LAN=$VRA_LAN" \
  -e "VRA_SCHEDULER=$VRA_SCHEDULER" \
  -e "VRA_API_TOKEN=$VRA_API_TOKEN" \
  -e "VRA_REMOTE=$VRA_REMOTE" \
  -e "VRA_ACCESS_TOKEN=$VRA_ACCESS_TOKEN" \
  -e "VRA_PUBLIC_URL=$VRA_PUBLIC_URL" \
  -e "VRA_PROVIDER=$VRA_PROVIDER" \
  -e "DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY" \
  -e "ZAI_API_KEY=$ZAI_API_KEY" \
  -e "MOONSHOT_API_KEY=$MOONSHOT_API_KEY" \
  -e "MIMO_API_KEY=$MIMO_API_KEY" \
  -e "OPENAI_API_KEY=$OPENAI_API_KEY" \
  -e "DASHSCOPE_API_KEY=$DASHSCOPE_API_KEY" \
  -e "SELFHOSTED_API_KEY=$SELFHOSTED_API_KEY" \
  -v vibe_astock_data:/data \
  "$IMAGE_NAME"

docker "$@"
