FROM ghcr.io/openclaw/openclaw:latest

# Als Root, um Pakete zu installieren
USER root

# Beispiel: curl und htop installieren (ersetze durch deine Pakete)
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    lsof \
    cargo \
    && npm install -g --force npm@latest pnpm@latest playwright@latest brace-expansion@latest ip-address@latest tar@latest undici@latest nanoid@latest \
    && cp -rf /usr/local/lib/node_modules/brace-expansion /usr/local/lib/node_modules/ip-address /usr/local/lib/node_modules/tar /usr/local/lib/node_modules/undici /usr/local/lib/node_modules/npm/node_modules/ 2>/dev/null || true \
    && rm -rf /usr/local/share/corepack \
    && mkdir -p /tmp/patch && cd /tmp/patch \
    && npm install @opentelemetry/propagator-jaeger@latest @vitest/browser@latest adm-zip@latest brace-expansion@latest fast-uri@latest ip-address@latest postcss@latest tar@latest undici@latest nanoid@latest \
    && rm -rf /app/node_modules/tar /app/node_modules/undici /app/node_modules/ws /app/node_modules/nanoid /app/node_modules/brace-expansion /app/node_modules/ip-address /app/node_modules/adm-zip 2>/dev/null || true \
    && cp -rf /tmp/patch/node_modules/* /app/node_modules/ \
    && find /app/node_modules -type d -name "nanoid" -exec cp -rf /tmp/patch/node_modules/nanoid/* {}/ \; \
    && find /app/node_modules -type d -name "undici" -exec cp -rf /tmp/patch/node_modules/undici/* {}/ \; \
    && find /app/node_modules -type d -name "tar" -exec cp -rf /tmp/patch/node_modules/tar/* {}/ \; \
    && find /app/node_modules -type d -name "brace-expansion" -exec cp -rf /tmp/patch/node_modules/brace-expansion/* {}/ \; \
    && find /app/node_modules -type d -name "ip-address" -exec cp -rf /tmp/patch/node_modules/ip-address/* {}/ \; \
    && find /app/node_modules -type d -name "adm-zip" -exec cp -rf /tmp/patch/node_modules/adm-zip/* {}/ \; \
    && cd /app && rm -rf /tmp/patch \
    && (npx --yes playwright install --with-deps chromium || (sleep 2 && npx --yes playwright install chromium)) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Zurück zum OpenClaw User
USER 1000:1000
