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
    && rm -rf /var/lib/apt/lists/*

ARG SHFMT_VERSION=3.14.1
ARG KUBECONFORM_VERSION=0.8.0
ARG KUBESCORE_VERSION=1.20.0
ARG KUSTOMIZE_VERSION=5.8.1
ARG TRIVY_VERSION=0.74.0
ARG TRUFFLEHOG_VERSION=3.97.4

WORKDIR /tmp/bin

# 1. shfmt
RUN curl -sL "https://github.com/mvdan/sh/releases/download/v${SHFMT_VERSION}/shfmt_v${SHFMT_VERSION}_linux_amd64" -o shfmt \
    && chmod +x shfmt

# 2. kubeconform
RUN curl -sL "https://github.com/yannh/kubeconform/releases/download/v${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz" | tar -xz kubeconform \
    && chmod +x kubeconform

# 3. kube-score
RUN curl -sL "https://github.com/zegl/kube-score/releases/download/v${KUBESCORE_VERSION}/kube-score_${KUBESCORE_VERSION}_linux_amd64.tar.gz" | tar -xz kube-score \
    && chmod +x kube-score

# 4. kustomize
RUN curl -sL "https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv${KUSTOMIZE_VERSION}/kustomize_v${KUSTOMIZE_VERSION}_linux_amd64.tar.gz" | tar -xz kustomize \
    && chmod +x kustomize

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
    && pre-commit --version \
    && ansible --version \
    && pytest --version
