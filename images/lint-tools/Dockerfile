# Multi-stage lightweight DevOps & Linting Container
# Base: Debian Trixie (13) Slim with standard APT packages + Go binaries
# ==============================================================================

# Stage 1: Tool Downloader (Builder)
# ------------------------------------------------------------------------------
FROM debian:trixie-slim AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install --no-install-recommends -y \
        curl=8.14.1-2+deb13u5 \
        ca-certificates=20250419 \
        tar=1.35+dfsg-3.1 \
        gzip=1.13-1+deb13u1 \
        git=1:2.47.3-0+deb13u1 \
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
ARG HADOLINT_VERSION=2.12.0

WORKDIR /tmp/bin

# Build Go-based CLI utilities from source with Go 1.27.1
RUN build_go_tool() ( \
        repo="$1"; tag="$2"; name="$3"; subpath="${4:-.}"; shift 4 || true; \
        git clone --depth 1 --branch "$tag" "$repo" "/tmp/$name" \
        && mkdir -p "/tmp/licenses/$name" \
        && cp "/tmp/$name"/LICENSE* "/tmp/licenses/$name/" 2>/dev/null || true \
        && rm -rf "/tmp/$name/vendor" \
        && if [ "$#" -gt 0 ]; then go -C "/tmp/$name/$subpath" get "$@" || true; fi \
        && go -C "/tmp/$name/$subpath" mod tidy \
        && CGO_ENABLED=0 GOWORK=off go -C "/tmp/$name/$subpath" build -mod=mod -ldflags="-s -w" -o "/tmp/bin/$name" . \
        && rm -rf "/tmp/$name"; \
    ) \
    && build_go_tool https://github.com/mvdan/sh.git "v${SHFMT_VERSION}" shfmt cmd/shfmt \
    && build_go_tool https://github.com/yannh/kubeconform.git "v${KUBECONFORM_VERSION}" kubeconform cmd/kubeconform \
    && build_go_tool https://github.com/zegl/kube-score.git "v${KUBESCORE_VERSION}" kube-score cmd/kube-score "golang.org/x/text@latest" "golang.org/x/net@latest" \
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

# 7. hadolint
RUN mkdir -p /tmp/licenses/hadolint \
    && curl -sL "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" -o /tmp/bin/hadolint \
    && chmod +x /tmp/bin/hadolint \
    && curl -fsSL "https://raw.githubusercontent.com/hadolint/hadolint/master/LICENSE" -o /tmp/licenses/hadolint/LICENSE


# Stage 2: Runtime Image
# ------------------------------------------------------------------------------
FROM debian:trixie-slim

LABEL org.opencontainers.image.title="lint-tools" \
      org.opencontainers.image.description="DevOps linting, secrets scanning, and validation toolchain on Debian Trixie" \
      org.opencontainers.image.authors="Patrick Bumüller"

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install linters, python, and utilities via standard APT package manager
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
        bash=5.2.37-2+b10 \
        git=1:2.47.3-0+deb13u1 \
        curl=8.14.1-2+deb13u5 \
        openssh-client=1:10.0p1-7+deb13u4 \
        ca-certificates=20250419 \
        libxml2-utils=2.12.7+dfsg+really2.9.14-2.1+deb13u3 \
        shellcheck=0.10.0-1 \
        yamllint=1.37.1-1 \
        python3=3.13.5-1 \
        python3-pip=25.1.1+dfsg-1 \
        python3-pytest=8.3.5-2 \
    && pip install --no-cache-dir --break-system-packages --ignore-installed \
        uv==0.12.17 \
        pre-commit==4.6.2 \
        ansible-core==2.21.4 \
        ansible-lint==26.8.0 \
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
    && hadolint --version \
    && yamllint --version \
    && uv --version \
    && pre-commit --version \
    && ansible --version \
    && pytest --version
