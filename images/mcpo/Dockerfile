FROM node:26-slim@sha256:e4db4c914bf8ad241bd24804fc25d272d89bad97e68cdc8a1414862790a02c39

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
  python3=3.11.2-1+b1 \
  python3-pip=23.0.1+dfsg-1 \
  python3-venv=3.11.2-1+b1 \
  git=1:2.39.5-0+deb12u3 \
  curl=7.88.1-10+deb12u15 \
  libexpat1=2.5.0-1+deb12u5 \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

# Upgrade global npm and patch npm's internal dependencies (tar, brace-expansion, ip-address, undici)
RUN npm install -g --force npm@latest brace-expansion@latest ip-address@latest tar@latest undici@latest \
  && for pkg in brace-expansion ip-address tar undici; do \
       if [ -d "/usr/local/lib/node_modules/$pkg" ]; then \
         cp -rf "/usr/local/lib/node_modules/$pkg" /usr/local/lib/node_modules/npm/node_modules/; \
       fi; \
     done

# Install uv, mcpo gateway, and pinned dependencies
RUN pip3 install --no-cache-dir --break-system-packages \
  uv==0.13.5 \
  mcp==1.30.0 \
  mcpo==0.0.20 \
  certifi==2026.10.19 \
  setuptools==84.2.1

LABEL org.opencontainers.image.title="mcpo" \
      org.opencontainers.image.description="Model Context Protocol gateway & uvx runner bridge" \
      org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
      org.opencontainers.image.upstream="https://github.com/open-webui/mcpo" \
      org.opencontainers.image.licenses="MIT"

# Retain upstream license for compliance
RUN mkdir -p /usr/local/share/licenses/mcpo \
  && curl -fsSL https://raw.githubusercontent.com/open-webui/mcpo/main/LICENSE -o /usr/local/share/licenses/mcpo/LICENSE

# Verify CLI binaries execute cleanly
RUN mcpo --help >/dev/null && uv --version >/dev/null

ENV PATH="/usr/local/bin:$PATH"
WORKDIR /app

USER 1000:1000

# Use mcpo from PATH since pip3 install puts it in /usr/local/bin
ENTRYPOINT ["mcpo"]
CMD ["--config", "/app/config.json", "--port", "9000"]
