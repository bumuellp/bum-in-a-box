FROM ghcr.io/openclaw/openclaw@sha256:ea298b62be8955d3ef750e2004a610dd90c3a30e5f9886e5d654d78a0c573218

LABEL org.opencontainers.image.title="openclaw" \
      org.opencontainers.image.description="Hardened autonomous web browsing and agent execution stack" \
      org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
      org.opencontainers.image.upstream="https://github.com/openclaw/openclaw" \
      org.opencontainers.image.licenses="MIT"

# Switch to root for system package management and hardening
USER 0:0

# Install system dependencies and clean up package manager caches
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    cargo=0.66.0+ds1-1 \
    curl=7.88.1-10+deb12u15 \
    lsof=4.95.0-1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Retain upstream license for compliance
RUN mkdir -p /usr/local/share/licenses/openclaw \
    && curl -fsSL https://raw.githubusercontent.com/openclaw/openclaw/main/LICENSE -o /usr/local/share/licenses/openclaw/LICENSE

# Execute supply-chain CVE remediation and toolchain upgrades
COPY patch-cves.sh /tmp/patch-cves.sh
RUN chmod +x /tmp/patch-cves.sh \
    && /tmp/patch-cves.sh \
    && rm -f /tmp/patch-cves.sh

# Install Playwright browser dependencies and clean up apt lists
RUN (npx --yes playwright install --with-deps chromium || (sleep 2 && npx --yes playwright install chromium)) \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Switch back to unprivileged OpenClaw user
USER 1000:1000
