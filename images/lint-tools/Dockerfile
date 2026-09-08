# Multi-stage lightweight DevOps & Linting Container
# Base: Debian Trixie (13) Slim with standard APT packages + Go binaries
# ==============================================================================

# Stage 1: Tool Downloader (Builder)
# ------------------------------------------------------------------------------
FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install --no-install-recommends -y \
        curl \
        ca-certificates \
        tar \
        gzip \
        git \
    && rm -rf /var/lib/apt/lists/*

# Install official Go 1.27.1 distribution
RUN TARGETARCH="$(uname -m)" \
    && if [ "$TARGETARCH" = "x86_64" ]; then GOARCH="amd64"; \
       elif [ "$TARGETARCH" = "aarch64" ]; then GOARCH="arm64"; \
       else GOARCH="amd64"; fi \
    && curl -fsSL "https://dl.google.com/go/go1.27.1.linux-${GOARCH}.tar.gz" | tar -C /usr/local -xz

ENV PATH="/usr/local/go/bin:${PATH}"

ARG SHFMT_VERSION=3.14.1
ARG KUBECONFORM_VERSION=0.8.0
ARG KUBESCORE_VERSION=1.20.0
ARG KUSTOMIZE_VERSION=v5.8.1
ARG TRIVY_VERSION=0.74.0
ARG TRUFFLEHOG_VERSION=3.97.4

WORKDIR /tmp/bin

# 1. shfmt (built from source with Go 1.27.1)
RUN git clone --depth 1 --branch v${SHFMT_VERSION} https://github.com/mvdan/sh.git /tmp/sh \
    && cd /tmp/sh \
    && rm -rf vendor \
    && go get golang.org/x/text@latest || true \
    && go mod tidy \
    && CGO_ENABLED=0 GOWORK=off go build -ldflags="-s -w" -o /tmp/bin/shfmt ./cmd/shfmt \
    && rm -rf /tmp/sh

# 2. kubeconform (built from source with Go 1.27.1 and patched x/text)
RUN git clone --depth 1 --branch v${KUBECONFORM_VERSION} https://github.com/yannh/kubeconform.git /tmp/kubeconform \
    && cd /tmp/kubeconform \
    && rm -rf vendor \
    && go get golang.org/x/text@latest \
    && go mod tidy \
    && CGO_ENABLED=0 GOWORK=off go build -ldflags="-s -w" -o /tmp/bin/kubeconform ./cmd/kubeconform \
    && rm -rf /tmp/kubeconform

# 3. kube-score (built from source with Go 1.27.1, patched x/text and x/net)
RUN git clone --depth 1 --branch v${KUBESCORE_VERSION} https://github.com/zegl/kube-score.git /tmp/kube-score \
    && cd /tmp/kube-score \
    && rm -rf vendor \
    && go get golang.org/x/text@latest golang.org/x/net@latest \
    && go mod tidy \
    && CGO_ENABLED=0 GOWORK=off go build -ldflags="-s -w" -o /tmp/bin/kube-score ./cmd/kube-score \
    && rm -rf /tmp/kube-score

# 4. kustomize (built from source with Go 1.27.1 and patched x/text)
RUN git clone --depth 1 --branch kustomize/${KUSTOMIZE_VERSION} https://github.com/kubernetes-sigs/kustomize.git /tmp/kustomize \
    && cd /tmp/kustomize/kustomize \
    && rm -rf vendor \
    && go get golang.org/x/text@latest \
    && go mod tidy \
    && CGO_ENABLED=0 GOWORK=off go build -ldflags="-s -w" -o /tmp/bin/kustomize . \
    && rm -rf /tmp/kustomize

# 5. trivy
RUN curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | tar -xz trivy \
    && chmod +x trivy

# 6. trufflehog
RUN curl -sL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz" | tar -xz trufflehog \
    && chmod +x trufflehog



# Stage 2: Runtime Image
# ------------------------------------------------------------------------------
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="lint-tools" \
      org.opencontainers.image.description="DevOps linting, secrets scanning, and validation toolchain on Debian Trixie" \
      org.opencontainers.image.authors="Patrick Bumüller"

ENV DEBIAN_FRONTEND=noninteractive

# Install linters, python, and utilities via standard APT package manager
RUN apt-get update && apt-get install --no-install-recommends -y \
        bash \
        git \
        curl \
        openssh-client \
        ca-certificates \
        libxml2-utils \
        shellcheck \
        yamllint \
        python3 \
        python3-pip \
        python3-pytest \
    && pip install --no-cache-dir --break-system-packages --ignore-installed \
        uv \
        pre-commit \
        ansible-core \
        ansible-lint \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Copy pre-compiled Go binaries from builder
COPY --from=builder /tmp/bin/* /usr/local/bin/

# Create a non-root user with home directory and workspace
RUN useradd -u 1000 -m -d /home/appuser -s /bin/bash appuser \
    && mkdir -p /home/appuser/.ansible /home/appuser/.cache /workspace \
    && chown -R 1000:1000 /home/appuser /workspace

ENV HOME=/home/appuser
ENV PRE_COMMIT_HOME=/tmp/pre-commit
ENV ANSIBLE_LOCAL_TEMP=/tmp/ansible

# Default workspace directory
WORKDIR /workspace

USER 1000:1000

# Verify all tools execute cleanly
RUN shellcheck --version \
    && shfmt --version \
    && kubeconform -v \
    && kube-score version \
    && kustomize version \
    && trivy --version \
    && trufflehog --version \
    && yamllint --version \
    && uv --version \
    && pre-commit --version \
    && ansible --version \
    && pytest --version
