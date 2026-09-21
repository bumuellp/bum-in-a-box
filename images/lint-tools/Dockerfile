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
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.1 /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"

ARG SHFMT_VERSION=3.14.1
ARG KUBECONFORM_VERSION=0.8.0
ARG KUBESCORE_VERSION=1.20.0
ARG KUSTOMIZE_VERSION=v5.8.1
ARG TRIVY_VERSION=0.74.0
ARG TRUFFLEHOG_VERSION=3.97.4

WORKDIR /tmp/bin

# Build Go-based CLI utilities from source with Go 1.27.1
RUN build_go_tool() ( \
        repo="$1"; tag="$2"; name="$3"; subpath="${4:-.}"; extra_pkgs="${5:-golang.org/x/text@latest}"; \
        git clone --depth 1 --branch "$tag" "$repo" "/tmp/$name" \
        && cd "/tmp/$name" \
        && mkdir -p "/tmp/licenses/$name" \
        && cp LICENSE* "/tmp/licenses/$name/" 2>/dev/null || true \
        && rm -rf vendor \
        && cd "/tmp/$name/$subpath" \
        && go get $extra_pkgs || true \
        && go mod tidy \
        && CGO_ENABLED=0 GOWORK=off go build -mod=mod -ldflags="-s -w" -o "/tmp/bin/$name" . \
        && rm -rf "/tmp/$name"; \
    ) \
    && build_go_tool https://github.com/mvdan/sh.git "v${SHFMT_VERSION}" shfmt cmd/shfmt \
    && build_go_tool https://github.com/yannh/kubeconform.git "v${KUBECONFORM_VERSION}" kubeconform cmd/kubeconform \
    && build_go_tool https://github.com/zegl/kube-score.git "v${KUBESCORE_VERSION}" kube-score cmd/kube-score "golang.org/x/text@latest golang.org/x/net@latest" \
    && build_go_tool https://github.com/kubernetes-sigs/kustomize.git "kustomize/${KUSTOMIZE_VERSION}" kustomize kustomize


# 5. trivy
RUN mkdir -p /tmp/licenses/trivy \
    && curl -sL "https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz" | tar -xz -C /tmp/licenses/trivy LICENSE trivy \
    && mv /tmp/licenses/trivy/trivy /tmp/bin/trivy \
    && chmod +x /tmp/bin/trivy

# 6. trufflehog
RUN mkdir -p /tmp/licenses/trufflehog \
    && curl -sL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp/licenses/trufflehog LICENSE trufflehog \
    && mv /tmp/licenses/trufflehog/trufflehog /tmp/bin/trufflehog \
    && chmod +x /tmp/bin/trufflehog



# Stage 2: Runtime Image
# ------------------------------------------------------------------------------
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="lint-tools" \
      org.opencontainers.image.description="DevOps linting, secrets scanning, and validation toolchain on Debian Trixie" \
      org.opencontainers.image.authors="Patrick Bumüller"

ENV DEBIAN_FRONTEND=noninteractive

# Install linters, python, and utilities via standard APT package manager
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
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

# Copy pre-compiled Go binaries and third-party licenses from builder
COPY --from=builder /tmp/bin/* /usr/local/bin/
COPY --from=builder /tmp/licenses/ /usr/local/share/licenses/

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
