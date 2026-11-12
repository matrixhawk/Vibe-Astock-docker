#!/usr/bin/env sh
set -eu

data_root="${VRA_DATA_ROOT:-/data/.local}"
api_port="${VRA_API_PORT:-8770}"
ui_port="${VRA_UI_PORT:-8080}"
token="${VRA_API_TOKEN:-}"

if [ -z "$token" ] && [ -r "$data_root/api.token" ]; then
  token="$(cat "$data_root/api.token")"
fi

[ -n "$token" ]
curl -fsS -H "Authorization: Bearer $token" "http://127.0.0.1:$api_port/health" >/dev/null

if [ "${VRA_REMOTE:-}" = "1" ]; then
  access_token="${VRA_ACCESS_TOKEN:-}"
  [ -n "$access_token" ]
  curl -fsS -H "Cookie: vibe_astock_access=$access_token" "http://127.0.0.1:$ui_port/" >/dev/null
else
  curl -fsS "http://127.0.0.1:$ui_port/" >/dev/null
fi
