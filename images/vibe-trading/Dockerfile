# Multi-stage Dockerfile for HKUDS Vibe-Trading integration into Podman LLM Stack

# Stage 0: Fetch Vibe-Trading source code from GitHub
ARG VIBE_TRADING_REPO=https://github.com/HKUDS/Vibe-Trading.git
ARG VIBE_TRADING_REF=main
FROM alpine/git:v2.54.1@sha256:2306e2b05ee0ef99f5d25b0779f645b24ae9f91ba187107503592fcdfe78da3a AS src
WORKDIR /src
ARG VIBE_TRADING_REPO
ARG VIBE_TRADING_REF
RUN git clone ${VIBE_TRADING_REPO} . && git checkout ${VIBE_TRADING_REF}

# Stage 1: Build Web UI frontend
FROM node:26-slim@sha256:e6bedef217677b276c591795e169840edd9096dbf13f29df8ef8d1856b8820bc AS frontend-build
WORKDIR /app/frontend
COPY --from=src /src/frontend/package.json /src/frontend/package-lock.json ./
RUN npm ci --ignore-scripts
COPY --from=src /src/frontend ./
RUN npm run build

# Stage 2: Python builder — compiles venv with dependencies
FROM python:3.14-slim@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && apt-get clean \
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
    && pip install --no-cache-dir --upgrade "wheel>=0.46.2" "jaraco.context>=6.1.0" "setuptools>=78.1.1" "urllib3>=2.8.0" "aiohttp>=3.14.4" "certifi>=2026.10.19" "pillow>=13.0.0" "dnspython>=2.9.2" "soupsieve>=4.0.0" \
    && rm -rf /opt/venv/lib/python*/site-packages/pip* /opt/venv/lib/python*/site-packages/setuptools* /opt/venv/lib/python*/site-packages/wheel* /opt/venv/bin/pip*

# Stage 3: Minimal secure runtime stage
FROM python:3.14-slim@sha256:9aaa474097d094040649f2162a627c0049b408f52138d980916788d80f04802f AS runtime

LABEL org.opencontainers.image.title="Vibe-Trading" \
    org.opencontainers.image.description="Natural-language finance research AI agent with backtesting" \
    org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
    org.opencontainers.image.upstream="https://github.com/HKUDS/Vibe-Trading" \
    org.opencontainers.image.licenses="MIT"

WORKDIR /app

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    libexpat1 \
    libpango-1.0-0 \
    libpangoft2-1.0-0 \
    libharfbuzz0b \
    libfontconfig1 \
    libgdk-pixbuf-2.0-0 \
    libcairo2 \
    fonts-dejavu-core \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /usr/local/lib/python*/site-packages/*

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder /opt/venv /opt/venv

RUN mkdir -p /usr/local/share/licenses/vibe-trading
COPY --from=src /src/pyproject.toml /src/LICENSE /src/README.md ./
COPY --from=src /src/LICENSE /usr/local/share/licenses/vibe-trading/LICENSE
COPY --from=src /src/agent/ agent/
COPY --from=frontend-build /app/frontend/dist frontend/dist

RUN useradd --create-home --uid 1000 --shell /usr/sbin/nologin vibe \
    && useradd --system --no-create-home --shell /usr/sbin/nologin --uid 10001 vibe-sandbox \
    && mkdir -p agent/runs agent/sessions agent/uploads agent/.swarm/runs /home/vibe/.vibe-trading \
    && chown -R vibe:vibe /app /home/vibe/.vibe-trading

USER 1000:1000

EXPOSE 8899

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8899/live')" || exit 1

CMD ["vibe-trading", "serve", "--host", "0.0.0.0", "--port", "8899"]
