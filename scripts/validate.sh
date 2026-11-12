#!/usr/bin/env sh
set -eu

sh -n docker/entrypoint.sh
sh -n docker/healthcheck.sh
sh -n scripts/check-upstream-v2.sh
sh -n scripts/build.sh
sh -n scripts/run.sh
sh -n scripts/validate.sh

if [ -e docker/nginx.conf ] || [ -e docker/patches/mimo-model.patch ]; then
  echo "stale v1 Docker files are still present" >&2
  exit 1
fi

grep -q 'orchestrator-deps' Dockerfile
grep -q 'desktop/node_modules/vite/bin/vite.js' docker/entrypoint.sh

if command -v docker >/dev/null 2>&1; then
  docker compose config >/dev/null
else
  echo "docker not found; skipped docker compose config"
fi

echo "static validation passed"
