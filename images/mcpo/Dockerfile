FROM node:24-slim

RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
  python3 \
  python3-pip \
  python3-venv \
  git \
  curl \
  && rm -rf /var/lib/apt/lists/*

# Upgrade global npm and patch npm's internal dependencies (tar, sigstore, picomatch, brace-expansion, ip-address)
RUN npm install -g --force npm@latest brace-expansion@latest ip-address@latest tar@latest \
  && cp -rf /usr/local/lib/node_modules/brace-expansion /usr/local/lib/node_modules/ip-address /usr/local/lib/node_modules/tar /usr/local/lib/node_modules/npm/node_modules/ 2>/dev/null || true


# Install uv (needed for MCPs that use 'uvx' to spawn themselves)
RUN pip3 install --no-cache-dir --break-system-packages uv

# Install mcpo directly via pip with pinned mcp v1.x (to avoid breaking changes from mcp 2.x)
RUN pip3 install --no-cache-dir --break-system-packages "mcp>=1.10.1,<2.0.0" mcpo setuptools

LABEL org.opencontainers.image.title="mcpo" \
      org.opencontainers.image.description="Model Context Protocol gateway & uvx runner bridge" \
      org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
      org.opencontainers.image.upstream="https://github.com/open-webui/mcpo" \
      org.opencontainers.image.licenses="MIT"

# Retain upstream license for compliance
RUN mkdir -p /usr/local/share/licenses/mcpo \
  && curl -fsSL https://raw.githubusercontent.com/open-webui/mcpo/main/LICENSE -o /usr/local/share/licenses/mcpo/LICENSE 2>/dev/null || true

# Debug: verify installation
RUN echo "=== mcpo location ===" && which mcpo || echo "WARNING: which mcpo failed"
RUN echo "=== uv location ===" && which uv || echo "WARNING: which uv failed"

ENV PATH="/usr/local/bin:$PATH"
WORKDIR /app

USER node

# Use mcpo from PATH since pip3 install puts it in /usr/local/bin
ENTRYPOINT ["mcpo"]
CMD ["--config", "/app/config.json", "--port", "9000"]
