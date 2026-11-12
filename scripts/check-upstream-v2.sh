#!/usr/bin/env sh
set -eu

ROOT="${1:-.}"

required_files='desktop/package.json
desktop/package-lock.json
desktop/vite.config.ts
orchestrator/package.json
orchestrator/package-lock.json
orchestrator/src/api.ts
vibe-research.config.json
calc/cli.py
datasources/registry.json
providers/mimo.json
.agents/skills/data-access/scripts/requirements.txt'

required_dirs='desktop/src
orchestrator/src
calc
datasources
providers
.agents/skills/data-access/scripts'

for relative in $required_files; do
  if [ ! -f "$ROOT/$relative" ]; then
    echo "上游 v2 契约失败：缺少文件 $relative" >&2
    exit 1
  fi
done

for relative in $required_dirs; do
  if [ ! -d "$ROOT/$relative" ]; then
    echo "上游 v2 契约失败：缺少目录 $relative" >&2
    exit 1
  fi
done

if [ -f "$ROOT/server.py" ] || [ -d "$ROOT/frontend" ]; then
  echo "上游 v2 契约失败：检测到 v1.x 的 server.py/frontend 结构，请停止发布并重新适配。" >&2
  exit 1
fi

echo "上游 v2 结构契约通过：desktop + orchestrator + Python data-access"
