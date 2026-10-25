# Multi-stage lightweight DevOps & Linting Container
# Base: Debian Trixie (13) Slim with standard APT packages + Go binaries
# ==============================================================================

# Stage 1: Tool Downloader (Builder)
# ------------------------------------------------------------------------------
FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f AS builder

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update && apt-get install --no-install-recommends -y \
        curl=8.14.1-2+deb13u7 \
        ca-certificates=20250419 \
        tar=1.35+dfsg-3.1 \
        gzip=1.13-1+deb13u1 \
        git=1:2.47.3-0+deb13u1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.2@sha256:820153096fda4de6ac1b7194d12e416b7dd8f4e9a33d17e0345b111b945162d8 /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"

ARG SHFMT_VERSION=3.14.1
ARG KUBECONFORM_VERSION=0.8.0
ARG KUBESCORE_VERSION=1.20.0
ARG KUSTOMIZE_VERSION=v5.8.1
ARG TRIVY_VERSION=0.75.0
ARG TRUFFLEHOG_VERSION=3.97.4
ARG HADOLINT_VERSION=2.12.0
ARG OPENTOFU_VERSION=1.13.1
ARG GOLANG_X_TEXT_VERSION=v0.42.0

ARG GOLANG_X_NET_VERSION=v0.60.0

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
    && build_go_tool https://github.com/yannh/kubeconform.git "v${KUBECONFORM_VERSION}" kubeconform cmd/kubeconform "golang.org/x/text@${GOLANG_X_TEXT_VERSION}" \
    && build_go_tool https://github.com/zegl/kube-score.git "v${KUBESCORE_VERSION}" kube-score cmd/kube-score "golang.org/x/text@${GOLANG_X_TEXT_VERSION}" "golang.org/x/net@${GOLANG_X_NET_VERSION}" \
    && build_go_tool https://github.com/kubernetes-sigs/kustomize.git "kustomize/${KUSTOMIZE_VERSION}" kustomize kustomize "golang.org/x/text@${GOLANG_X_TEXT_VERSION}"


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

# 8. opentofu
RUN mkdir -p /tmp/licenses/opentofu \
    && curl -sL "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_amd64.tar.gz" | tar -xz -C /tmp/licenses/opentofu LICENSE tofu \
    && mv /tmp/licenses/opentofu/tofu /tmp/bin/tofu \
    && chmod +x /tmp/bin/tofu

# 9. jq
# renovate: datasource=github-releases depName=jqlang/jq
ARG JQ_VERSION=1.7.1
RUN mkdir -p /tmp/licenses/jq \
    && curl -sL "https://github.com/jqlang/jq/releases/download/jq-${JQ_VERSION}/jq-linux-amd64" -o /tmp/bin/jq \
    && chmod +x /tmp/bin/jq \
    && curl -fsSL "https://raw.githubusercontent.com/jqlang/jq/master/COPYING" -o /tmp/licenses/jq/LICENSE

# 10. hcloud
# renovate: datasource=github-releases depName=hetznercloud/cli
ARG HCLOUD_VERSION=v1.70.2
RUN mkdir -p /tmp/licenses/hcloud \
    && curl -sL "https://github.com/hetznercloud/cli/releases/download/${HCLOUD_VERSION}/hcloud-linux-amd64.tar.gz" | tar -xz -C /tmp/bin hcloud \
    && chmod +x /tmp/bin/hcloud \
    && curl -fsSL "https://raw.githubusercontent.com/hetznercloud/cli/master/LICENSE" -o /tmp/licenses/hcloud/LICENSE

# 11. Rust toolchain for linting (cargo, clippy, rustfmt)
ARG RUST_VERSION=1.99.0
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y \
        --default-toolchain "${RUST_VERSION}" \
        --profile minimal \
        --component clippy,rustfmt \
    && chmod -R a+rx /usr/local/cargo /usr/local/rustup \
    && chmod -R a+rwX /usr/local/cargo



# Stage 2: Runtime Image
# ------------------------------------------------------------------------------
FROM debian:trixie-slim@sha256:a29215f6a35e51e22adffa17f89e9d2ef06214e64a2bad10d765c46aea49f11f

LABEL org.opencontainers.image.title="lint-tools" \
      org.opencontainers.image.description="DevOps linting, secrets scanning, and validation toolchain on Debian Trixie" \
      org.opencontainers.image.authors="Patrick Bumüller"

ENV DEBIAN_FRONTEND=noninteractive

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install linters, python, and utilities via standard APT package manager
RUN apt-get update && apt-get upgrade -y && apt-get install --no-install-recommends -y \
        bash=5.2.37-2+b10 \
        git=1:2.47.3-0+deb13u1 \
        curl=8.14.1-2+deb13u7 \
        openssh-client=1:10.0p1-7+deb13u4 \
        ca-certificates=20250419 \
        libxml2-utils=2.12.7+dfsg+really2.9.14-2.1+deb13u3 \
        libexpat1=2.9.0-1~deb13u1 \
        shellcheck=0.10.0-1 \
        yamllint=1.37.1-1 \
        python3=3.13.5-1 \
        python3-pip=25.1.1+dfsg-1 \
        python3-pytest=8.3.5-2 \
        gcc=4:14.2.0-1 \
        libc6-dev=2.41-12+deb13u4 \
    && pip install --no-cache-dir --break-system-packages --ignore-installed \
        uv==0.13.5 \
        pre-commit==4.6.2 \
        ansible-core==2.21.4 \
        ansible-lint==26.8.0 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /root/.cache

# Copy pre-compiled Go binaries and third-party licenses from builder
COPY --from=builder /tmp/bin/* /usr/local/bin/
COPY --from=builder /tmp/licenses/ /usr/local/share/licenses/

# Copy Rust toolchain from builder
COPY --chown=1000:1000 --from=builder /usr/local/cargo /usr/local/cargo
COPY --chown=1000:1000 --from=builder /usr/local/rustup /usr/local/rustup

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
