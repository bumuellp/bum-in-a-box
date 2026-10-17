# Stage 1: Build llama-swap binary with official Go 1.27.2
FROM debian:bookworm-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587 AS go-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.39.5-0+deb12u3 \
    ca-certificates=20250419~deb12u1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.2@sha256:820153096fda4de6ac1b7194d12e416b7dd8f4e9a33d17e0345b111b945162d8 /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOTOOLCHAIN=auto

WORKDIR /src
ARG LLAMA_SWAP_REPO=https://github.com/mostlygeek/llama-swap.git
ARG LLAMA_SWAP_REF=main
ARG CACHEBUST=20260824
RUN /usr/local/go/bin/go version \
    && git clone --depth 1 ${LLAMA_SWAP_REPO} . && git checkout ${LLAMA_SWAP_REF} \
    && go get golang.org/x/net@v0.60.0 \
    && go mod tidy \
    && mkdir -p /build/licenses/llama-swap \
    && cp LICENSE* /build/licenses/llama-swap/ 2>/dev/null || true \
    && CGO_ENABLED=0 go build -ldflags="-s -w" -o /build/llama-swap . \
    && /usr/local/go/bin/go version -m /build/llama-swap

# Stage 2: Official GGML Vulkan runtime (native glibc, OpenSSL 3.3, and Vulkan drivers)
FROM ghcr.io/ggml-org/llama.cpp:server-vulkan@sha256:5096299bac58e2b24f0371221c83eac786b206165bf8235dabc83d3ed514eb48

LABEL org.opencontainers.image.title="llama-proxy" \
      org.opencontainers.image.description="llama-swap proxy with native Vulkan llama-server" \
      org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
      org.opencontainers.image.upstream="https://github.com/mostlygeek/llama-swap"

USER 0:0

# Upgrade system packages to patch upstream OpenSSL vulnerabilities (CVE-2026-84782)
RUN apt-get update && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Remove unused pebble binary inherited from upstream base image that contains Go stdlib CVEs
RUN rm -f /usr/bin/pebble

# Copy static llama-swap binary and license from Go builder stage
COPY --from=go-builder /build/llama-swap /usr/local/bin/llama-swap
COPY --from=go-builder /build/licenses/ /usr/local/share/licenses/

EXPOSE 5002
ENTRYPOINT ["/usr/local/bin/llama-swap"]

USER 1000:1000
