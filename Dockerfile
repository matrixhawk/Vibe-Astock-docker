# syntax=docker/dockerfile:1.7

ARG VIBE_ASTOCK_REPO=https://github.com/simonlin1212/vibe-astock.git
ARG VIBE_ASTOCK_REF=main

FROM node:22-bookworm-slim AS source
ARG VIBE_ASTOCK_REPO
ARG VIBE_ASTOCK_REF

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
RUN git clone --filter=blob:none --no-checkout "$VIBE_ASTOCK_REPO" . \
    && git fetch --depth 1 origin "$VIBE_ASTOCK_REF" \
    && git checkout --detach FETCH_HEAD

COPY scripts/check-upstream-v2.sh /usr/local/bin/check-upstream-v2
RUN chmod +x /usr/local/bin/check-upstream-v2 \
    && /usr/local/bin/check-upstream-v2 /src \
    && rm -rf /src/.git

FROM node:22-bookworm-slim AS desktop-builder
WORKDIR /src
COPY --from=source /src /src
WORKDIR /src/desktop

RUN --mount=type=cache,target=/root/.npm \
    npm ci --no-audit --no-fund
RUN npm run build

FROM node:22-bookworm-slim AS orchestrator-deps
WORKDIR /src/orchestrator
COPY --from=source /src/orchestrator/package.json /src/orchestrator/package-lock.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --omit=dev --no-audit --no-fund

FROM node:22-bookworm-slim AS python-deps
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        build-essential \
        libxml2-dev \
        libxslt1-dev \
        python3 \
        python3-venv \
    && rm -rf /var/lib/apt/lists/*

COPY --from=source /src/.agents/skills/data-access/scripts/requirements.txt /tmp/requirements.txt
RUN python3 -m venv /opt/venv \
    && /opt/venv/bin/pip install --upgrade pip \
    && /opt/venv/bin/pip install -r /tmp/requirements.txt

FROM node:22-bookworm-slim AS runtime

ENV NODE_ENV=production \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data \
    VRA_DATA_ROOT=/data/.local \
    VRA_UI_PORT=8080 \
    VRA_API_PORT=8770 \
    VRA_LAN=1 \
    VRA_PYTHON=/opt/venv/bin/python \
    VRA_SCHEDULER=on

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libxml2 \
        libxslt1.1 \
        python3 \
        tini \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=source /src /app
COPY --from=desktop-builder /src/desktop/dist /app/desktop/dist
COPY --from=desktop-builder /src/desktop/node_modules /app/desktop/node_modules
COPY --from=orchestrator-deps /src/orchestrator/node_modules /app/orchestrator/node_modules
COPY --from=python-deps /opt/venv /opt/venv
COPY docker/entrypoint.sh /usr/local/bin/vibe-astock-entrypoint
COPY docker/healthcheck.sh /usr/local/bin/vibe-astock-healthcheck

RUN chmod +x /usr/local/bin/vibe-astock-entrypoint /usr/local/bin/vibe-astock-healthcheck \
    && mkdir -p /data/.local

EXPOSE 8080
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD ["/usr/local/bin/vibe-astock-healthcheck"]

ENTRYPOINT ["tini", "--", "vibe-astock-entrypoint"]
