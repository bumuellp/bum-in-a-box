# Multi-stage lightweight DevOps & Linting Container
# Base: Debian Trixie (13) Slim with standard APT packages + Go binaries
# ==============================================================================

# Shared Go dependency overrides (imported per-stage for granular layer caching)
# renovate: datasource=go depName=golang.org/x/text
ARG GOLANG_X_TEXT_VERSION=v0.44.0
# renovate: datasource=go depName=golang.org/x/net
ARG GOLANG_X_NET_VERSION=v0.63.0
# renovate: datasource=go depName=golang.org/x/mod
ARG GOLANG_X_MOD_VERSION=v0.43.0
# renovate: datasource=go depName=github.com/go-jose/go-jose/v4
ARG GO_JOSE_VERSION=v4.1.9
# renovate: datasource=go depName=google.golang.org/grpc
ARG GRPC_VERSION=v1.85.0

# Base Downloader Stage
# ------------------------------------------------------------------------------
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2 AS builder-base

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install --no-install-recommends -y \
        curl \
        ca-certificates \
        tar \
        gzip \
        git \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Shared Go Builder Stage
# ------------------------------------------------------------------------------
FROM builder-base AS go-builder-base

COPY --from=golang:1.27.4@sha256:205c7636d74e0ffbe3d007162df7d74f859f5a8c8322dfb9f907977686c126cf /usr/local/go /usr/local/go
COPY build-go-tool.sh /usr/local/bin/build-go-tool
RUN chmod +x /usr/local/bin/build-go-tool

ENV PATH="/usr/local/go/bin:${PATH}"

# Per-Tool Parallel Builder Stages (isolated layer cache per tool)
# ------------------------------------------------------------------------------
FROM go-builder-base AS build-shfmt
# renovate: datasource=github-releases depName=mvdan/sh
ARG SHFMT_VERSION=3.14.1
RUN build-go-tool https://github.com/mvdan/sh.git "v${SHFMT_VERSION}" shfmt cmd/shfmt

FROM go-builder-base AS build-kubeconform
# renovate: datasource=github-releases depName=yannh/kubeconform
ARG KUBECONFORM_VERSION=0.8.0
ARG GOLANG_X_TEXT_VERSION
RUN build-go-tool https://github.com/yannh/kubeconform.git "v${KUBECONFORM_VERSION}" kubeconform cmd/kubeconform \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}"

FROM go-builder-base AS build-kubescore
# renovate: datasource=github-releases depName=zegl/kube-score
ARG KUBESCORE_VERSION=1.20.0
ARG GOLANG_X_TEXT_VERSION
ARG GOLANG_X_NET_VERSION
RUN build-go-tool https://github.com/zegl/kube-score.git "v${KUBESCORE_VERSION}" kube-score cmd/kube-score \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}" \
    "golang.org/x/net@${GOLANG_X_NET_VERSION}"

FROM go-builder-base AS build-kustomize
# renovate: datasource=github-releases depName=kubernetes-sigs/kustomize extractVersion=^kustomize/(?<version>.+)$
ARG KUSTOMIZE_VERSION=v5.8.1
ARG GOLANG_X_TEXT_VERSION
RUN build-go-tool https://github.com/kubernetes-sigs/kustomize.git "kustomize/${KUSTOMIZE_VERSION}" kustomize kustomize \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}"

FROM go-builder-base AS build-trivy
# renovate: datasource=github-releases depName=aquasecurity/trivy
ARG TRIVY_VERSION=0.76.2
ARG GOLANG_X_NET_VERSION
ARG GOLANG_X_TEXT_VERSION
ARG GOLANG_X_MOD_VERSION
ARG GO_JOSE_VERSION
ARG GRPC_VERSION
RUN EXTRA_LDFLAGS="-X github.com/aquasecurity/trivy/pkg/version/app.ver=${TRIVY_VERSION}" \
    build-go-tool https://github.com/aquasecurity/trivy.git "v${TRIVY_VERSION}" trivy cmd/trivy \
    "golang.org/x/net@${GOLANG_X_NET_VERSION}" \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}" \
    "golang.org/x/mod@${GOLANG_X_MOD_VERSION}" \
    "github.com/go-jose/go-jose/v4@${GO_JOSE_VERSION}" \
    "google.golang.org/grpc@${GRPC_VERSION}"

FROM go-builder-base AS build-tofu
# renovate: datasource=github-releases depName=opentofu/opentofu
ARG OPENTOFU_VERSION=1.13.9
ARG GOLANG_X_NET_VERSION
ARG GOLANG_X_TEXT_VERSION
ARG GOLANG_X_MOD_VERSION
ARG GO_JOSE_VERSION
ARG GRPC_VERSION
RUN EXTRA_LDFLAGS="-X github.com/opentofu/opentofu/version.dev=no" \
    build-go-tool https://github.com/opentofu/opentofu.git "v${OPENTOFU_VERSION}" tofu cmd/tofu \
    "golang.org/x/net@${GOLANG_X_NET_VERSION}" \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}" \
    "golang.org/x/mod@${GOLANG_X_MOD_VERSION}" \
    "github.com/go-jose/go-jose/v4@${GO_JOSE_VERSION}" \
    "google.golang.org/grpc@${GRPC_VERSION}"

FROM go-builder-base AS build-hcloud
# renovate: datasource=github-releases depName=hetznercloud/cli
ARG HCLOUD_VERSION=v1.70.2
ARG GOLANG_X_NET_VERSION
ARG GOLANG_X_TEXT_VERSION
RUN EXTRA_LDFLAGS="-X github.com/hetznercloud/cli/internal/version.versionPrerelease=" \
    build-go-tool https://github.com/hetznercloud/cli.git "${HCLOUD_VERSION}" hcloud cmd/hcloud \
    "golang.org/x/net@${GOLANG_X_NET_VERSION}" \
    "golang.org/x/text@${GOLANG_X_TEXT_VERSION}"

FROM builder-base AS build-trufflehog
# renovate: datasource=github-releases depName=trufflesecurity/trufflehog
ARG TRUFFLEHOG_VERSION=3.97.4
RUN mkdir -p /out/bin /out/share/licenses/trufflehog \
    && curl -fsSL "https://github.com/trufflesecurity/trufflehog/releases/download/v${TRUFFLEHOG_VERSION}/trufflehog_${TRUFFLEHOG_VERSION}_linux_amd64.tar.gz" -o /tmp/trufflehog.tar.gz \
    && tar -xzf /tmp/trufflehog.tar.gz -C /out/share/licenses/trufflehog LICENSE trufflehog \
    && mv /out/share/licenses/trufflehog/trufflehog /out/bin/trufflehog \
    && chmod +x /out/bin/trufflehog \
    && rm -f /tmp/trufflehog.tar.gz

FROM builder-base AS build-hadolint
# renovate: datasource=github-releases depName=hadolint/hadolint
ARG HADOLINT_VERSION=2.12.0
RUN mkdir -p /out/bin /out/share/licenses/hadolint \
    && curl -fsSL "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64" -o /out/bin/hadolint \
    && chmod +x /out/bin/hadolint \
    && curl -fsSL "https://raw.githubusercontent.com/hadolint/hadolint/master/LICENSE" -o /out/share/licenses/hadolint/LICENSE

FROM builder-base AS build-jq
# renovate: datasource=github-releases depName=jqlang/jq extractVersion=^jq-(?<version>.+)$
ARG JQ_VERSION=1.7.1
RUN mkdir -p /out/bin /out/share/licenses/jq \
    && curl -fsSL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" -o /out/bin/jq \
    && chmod +x /out/bin/jq \
    && curl -fsSL "https://raw.githubusercontent.com/jqlang/jq/master/COPYING" -o /out/share/licenses/jq/LICENSE

FROM builder-base AS build-rust
# renovate: datasource=github-releases depName=rust-lang/rust
ARG RUST_VERSION=1.99.0
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /tmp/rustup-init \
    && sh /tmp/rustup-init -y \
        --default-toolchain "${RUST_VERSION}" \
        --profile minimal \
        --component clippy,rustfmt \
    && rm -f /tmp/rustup-init \
    && chmod -R a+rx /usr/local/cargo /usr/local/rustup \
    && chmod -R a+rwX /usr/local/cargo

# Final Stage: Runtime Image
# ------------------------------------------------------------------------------
FROM debian:trixie-slim@sha256:a72b4433de1cf7d6bae0c4cee74d0547f58601a643b3375f070c51600d63b6b2

LABEL org.opencontainers.image.title="lint-tools" \
      org.opencontainers.image.description="DevOps linting, secrets scanning, and validation toolchain on Debian Trixie" \
      org.opencontainers.image.authors="Patrick Bumüller"

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install linters, python, and utilities via standard APT package manager
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
        bash \
        git \
        curl \
        openssh-client \
        ca-certificates \
        libxml2-utils \
        libexpat1 \
        libbrotli1 \
        shellcheck \
        yamllint \
        python3 \
        python3-pip \
        python3-pytest \
        gcc \
        libc6-dev \
    && pip install --no-cache-dir --break-system-packages --ignore-installed \
        uv==0.13.5 \
        pre-commit==4.6.2 \
        ansible-core==2.21.4 \
        ansible-lint==26.8.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Copy pre-compiled tools and third-party licenses from parallel builder stages
COPY --from=build-shfmt /out/ /usr/local/
COPY --from=build-kubeconform /out/ /usr/local/
COPY --from=build-kubescore /out/ /usr/local/
COPY --from=build-kustomize /out/ /usr/local/
COPY --from=build-trivy /out/ /usr/local/
COPY --from=build-tofu /out/ /usr/local/
COPY --from=build-hcloud /out/ /usr/local/
COPY --from=build-trufflehog /out/ /usr/local/
COPY --from=build-hadolint /out/ /usr/local/
COPY --from=build-jq /out/ /usr/local/

# Copy Rust toolchain from builder
COPY --chown=1000:1000 --from=build-rust /usr/local/cargo /usr/local/cargo
COPY --chown=1000:1000 --from=build-rust /usr/local/rustup /usr/local/rustup

# Create a non-root user with home directory and workspace
RUN useradd -u 1000 -m -d /home/appuser -s /bin/bash appuser \
    && mkdir -p /home/appuser/.ansible /home/appuser/.cache /home/appuser/.cargo /workspace \
    && chown -R 1000:1000 /home/appuser /workspace

ENV HOME=/home/appuser
ENV PRE_COMMIT_HOME=/tmp/pre-commit
ENV ANSIBLE_LOCAL_TEMP=/tmp/ansible
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH="/usr/local/cargo/bin:${PATH}"

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
    && tofu --version \
    && yamllint --version \
    && uv --version \
    && pre-commit --version \
    && ansible --version \
    && pytest --version \
    && cargo --version \
    && rustc --version \
    && rustfmt --version \
    && cargo clippy --version \
    && jq --version \
    && hcloud version
