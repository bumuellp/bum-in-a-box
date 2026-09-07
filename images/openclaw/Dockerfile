FROM ghcr.io/openclaw/openclaw:latest

# Als Root, um Pakete zu installieren
USER root

# Beispiel: curl und htop installieren (ersetze durch deine Pakete)
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    lsof \
    cargo \
    && npm install -g --force npm@latest pnpm@latest brace-expansion@latest ip-address@latest tar@latest undici@latest nanoid@latest \
    && cp -rf /usr/local/lib/node_modules/brace-expansion /usr/local/lib/node_modules/ip-address /usr/local/lib/node_modules/tar /usr/local/lib/node_modules/undici /usr/local/lib/node_modules/npm/node_modules/ 2>/dev/null || true \
    && rm -rf /usr/local/share/corepack \
    && mkdir -p /tmp/patch && cd /tmp/patch \
    && npm install @opentelemetry/propagator-jaeger@latest @vitest/browser@latest brace-expansion@latest fast-uri@latest ip-address@latest postcss@latest tar@latest undici@latest nanoid@latest \
    && cp -rf /tmp/patch/node_modules/* /app/node_modules/ \
    && find /app/node_modules -type d -name "nanoid" -exec cp -rf /tmp/patch/node_modules/nanoid/* {}/ \; \
    && find /app/node_modules -type d -name "undici" -exec cp -rf /tmp/patch/node_modules/undici/* {}/ \; \
    && find /app/node_modules -type d -name "tar" -exec cp -rf /tmp/patch/node_modules/tar/* {}/ \; \
    && find /app/node_modules -type d -name "brace-expansion" -exec cp -rf /tmp/patch/node_modules/brace-expansion/* {}/ \; \
    && find /app/node_modules -type d -name "ip-address" -exec cp -rf /tmp/patch/node_modules/ip-address/* {}/ \; \
    && cd /app && rm -rf /tmp/patch \
    && (npx playwright install --with-deps chromium || (sleep 2 && npx playwright install chromium)) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Zurück zum OpenClaw User
USER 1000:1000
