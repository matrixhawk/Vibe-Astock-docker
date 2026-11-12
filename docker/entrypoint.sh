#!/usr/bin/env sh
set -eu

: "${HOME:=/data}"
: "${VRA_DATA_ROOT:=/data/.local}"
: "${VRA_UI_PORT:=8080}"
: "${VRA_API_PORT:=8770}"
: "${VRA_PYTHON:=/opt/venv/bin/python}"
: "${VRA_LAN:=1}"
: "${VRA_SCHEDULER:=on}"
: "${VRA_API_TOKEN:=}"

export HOME VRA_DATA_ROOT VRA_UI_PORT VRA_API_PORT VRA_PYTHON VRA_LAN VRA_SCHEDULER VRA_API_TOKEN

mkdir -p "$HOME" "$VRA_DATA_ROOT"
cd /app

api_pid=""
ui_pid=""

shutdown() {
  status="${1:-0}"
  if [ -n "$ui_pid" ]; then kill "$ui_pid" 2>/dev/null || true; fi
  if [ -n "$api_pid" ]; then kill "$api_pid" 2>/dev/null || true; fi
  if [ -n "$ui_pid" ]; then wait "$ui_pid" 2>/dev/null || true; fi
  if [ -n "$api_pid" ]; then wait "$api_pid" 2>/dev/null || true; fi
  return "$status"
}

trap 'shutdown 0; exit 0' INT TERM HUP

node /app/orchestrator/src/api.ts \
  --host 127.0.0.1 \
  --port "$VRA_API_PORT" &
api_pid="$!"

api_ready() {
  token="$VRA_API_TOKEN"
  if [ -z "$token" ] && [ -r "$VRA_DATA_ROOT/api.token" ]; then
    token="$(cat "$VRA_DATA_ROOT/api.token")"
  fi
  [ -n "$token" ] || return 1
  curl -fsS \
    -H "Authorization: Bearer $token" \
    "http://127.0.0.1:$VRA_API_PORT/health" >/dev/null 2>&1
}

tries=0
while [ "$tries" -lt 150 ]; do
  if ! kill -0 "$api_pid" 2>/dev/null; then
    wait "$api_pid" || true
    echo "[vibe-astock] Node API 启动失败。" >&2
    exit 1
  fi
  if api_ready; then break; fi
  tries=$((tries + 1))
  sleep 0.2
done

if ! api_ready; then
  echo "[vibe-astock] 等待 Node API 就绪超时。" >&2
  shutdown 1
  exit 1
fi

(
  cd /app/desktop
  exec node /app/desktop/node_modules/vite/bin/vite.js preview \
    --host 0.0.0.0 \
    --port "$VRA_UI_PORT" \
    --strictPort
) &
ui_pid="$!"

status=0
while :; do
  if ! kill -0 "$api_pid" 2>/dev/null; then
    wait "$api_pid" || status="$?"
    break
  fi
  if ! kill -0 "$ui_pid" 2>/dev/null; then
    wait "$ui_pid" || status="$?"
    break
  fi
  sleep 1
done

shutdown "$status"
exit "$status"
