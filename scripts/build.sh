#!/usr/bin/env sh
set -eu

: "${IMAGE_NAME:=vibe-astock:local}"
: "${VIBE_ASTOCK_REPO:=https://github.com/simonlin1212/vibe-astock.git}"
: "${VIBE_ASTOCK_REF:=main}"

docker build "$@" \
  --build-arg "VIBE_ASTOCK_REPO=$VIBE_ASTOCK_REPO" \
  --build-arg "VIBE_ASTOCK_REF=$VIBE_ASTOCK_REF" \
  -t "$IMAGE_NAME" \
  .
