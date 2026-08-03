#!/usr/bin/env sh
set -eu

: "${HOME:=/data}"
: "${API_HOST:=127.0.0.1}"
: "${VIBE_PORT:=8910}"
: "${UVICORN_WORKERS:=1}"

mkdir -p "$HOME"
cd /app

python -m uvicorn server:app \
  --host "$API_HOST" \
  --port "$VIBE_PORT" \
  --workers "$UVICORN_WORKERS" \
  --proxy-headers &
api_pid="$!"

nginx -g "daemon off;" &
nginx_pid="$!"

shutdown() {
  kill "$api_pid" "$nginx_pid" 2>/dev/null || true
  wait "$api_pid" 2>/dev/null || true
  wait "$nginx_pid" 2>/dev/null || true
}

trap shutdown INT TERM

status=0
while :; do
  if ! kill -0 "$api_pid" 2>/dev/null; then
    wait "$api_pid" || status="$?"
    break
  fi

  if ! kill -0 "$nginx_pid" 2>/dev/null; then
    wait "$nginx_pid" || status="$?"
    break
  fi

  sleep 1
done

shutdown
exit "$status"
