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
RUN git clone --filter=blob:none "$VIBE_ASTOCK_REPO" . \
    && git fetch --depth 1 origin "$VIBE_ASTOCK_REF" \
    && git checkout FETCH_HEAD

FROM node:22-bookworm-slim AS frontend-builder
WORKDIR /src/frontend
COPY --from=source /src /src

RUN --mount=type=cache,target=/root/.npm \
    if [ -f package-lock.json ]; then npm ci; else npm install; fi
RUN npm run build

FROM python:3.12-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    HOME=/data \
    API_HOST=127.0.0.1 \
    VIBE_PORT=8910 \
    UVICORN_WORKERS=1

RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates curl nginx tini \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

WORKDIR /app
COPY --from=source /src/main.py /src/server.py /src/requirements.txt /app/
COPY --from=source /src/duanxian /app/duanxian
COPY --from=source /src/vr /app/vr
COPY --from=source /src/pytest.ini /app/pytest.ini
COPY --from=frontend-builder /src/frontend/dist /app/frontend/dist
COPY docker/nginx.conf /etc/nginx/sites-available/default
COPY docker/entrypoint.sh /usr/local/bin/vibe-astock-entrypoint

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --upgrade pip \
    && pip install -r requirements.txt \
    && mkdir -p /data \
    && chmod +x /usr/local/bin/vibe-astock-entrypoint

EXPOSE 8080
VOLUME ["/data"]

HEALTHCHECK --interval=30s --timeout=5s --start-period=45s --retries=3 \
    CMD curl -fsS http://127.0.0.1:8080/api/health || exit 1

ENTRYPOINT ["tini", "--", "vibe-astock-entrypoint"]
