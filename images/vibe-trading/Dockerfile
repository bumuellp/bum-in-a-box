# Multi-stage Dockerfile for HKUDS Vibe-Trading integration into Podman LLM Stack

# Stage 0: Fetch Vibe-Trading source code from GitHub
ARG VIBE_TRADING_REPO=https://github.com/HKUDS/Vibe-Trading.git
ARG VIBE_TRADING_REF=main
FROM alpine/git:latest AS src
WORKDIR /src
ARG VIBE_TRADING_REPO
ARG VIBE_TRADING_REF
RUN git clone ${VIBE_TRADING_REPO} . && git checkout ${VIBE_TRADING_REF}

# Stage 1: Build Web UI frontend
FROM node:22-slim@sha256:6c74791e557ce11fc957704f6d4fe134a7bc8d6f5ca4403205b2966bd488f6b3 AS frontend-build
WORKDIR /app/frontend
COPY --from=src /src/frontend/package.json /src/frontend/package-lock.json ./
RUN npm ci --ignore-scripts
COPY --from=src /src/frontend ./
RUN npm run build

# Stage 2: Python builder — compiles venv with dependencies
FROM python:3.11-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

ENV VIRTUAL_ENV=/opt/venv
RUN python -m venv "$VIRTUAL_ENV"
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

WORKDIR /app
COPY --from=src /src/agent/requirements.txt agent/requirements.txt
COPY --from=src /src/requirements-lock.txt requirements-lock.txt
RUN pip install --no-cache-dir --require-hashes -r requirements-lock.txt

COPY --from=src /src/pyproject.toml /src/LICENSE /src/README.md ./
COPY --from=src /src/agent/ agent/
RUN pip install --no-cache-dir -e . \
    && pip install --no-cache-dir --upgrade "wheel>=0.46.2" "jaraco.context>=6.1.0" "setuptools>=75.0.0"

# Stage 3: Minimal secure runtime stage
FROM python:3.11-slim AS runtime

LABEL org.opencontainers.image.title="Vibe-Trading" \
    org.opencontainers.image.description="Natural-language finance research AI agent with backtesting" \
    org.opencontainers.image.source="https://github.com/HKUDS/Vibe-Trading" \
    org.opencontainers.image.licenses="MIT"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libfontconfig1 \
    libgdk-pixbuf-2.0-0 \
    libcairo2 \
    fonts-dejavu-core \
    && rm -rf /var/lib/apt/lists/* \
    && pip install --no-cache-dir --upgrade "wheel>=0.46.2" "jaraco.context>=6.1.0" "setuptools>=75.0.0" 2>/dev/null || true

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder /opt/venv /opt/venv

COPY --from=src /src/pyproject.toml /src/LICENSE /src/README.md ./
COPY --from=src /src/agent/ agent/
COPY --from=frontend-build /app/frontend/dist frontend/dist

RUN useradd --create-home --shell /usr/sbin/nologin vibe \
    && useradd --system --no-create-home --shell /usr/sbin/nologin --uid 10001 vibe-sandbox \
    && mkdir -p agent/runs agent/sessions agent/uploads agent/.swarm/runs /home/vibe/.vibe-trading \
    && chown -R vibe:vibe /app /home/vibe/.vibe-trading

USER vibe

EXPOSE 8899

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8899/live')" || exit 1

CMD ["vibe-trading", "serve", "--host", "0.0.0.0", "--port", "8899"]
