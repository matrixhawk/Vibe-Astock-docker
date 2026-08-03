#!/usr/bin/env sh
set -eu

sh -n docker/entrypoint.sh
sh -n scripts/build.sh
sh -n scripts/run.sh
sh -n scripts/validate.sh

if command -v docker >/dev/null 2>&1; then
  docker compose config >/dev/null
else
  echo "docker not found; skipped docker compose config"
fi

echo "static validation passed"
