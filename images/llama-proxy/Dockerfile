# Stage 1: Build llama-swap binary with official Go 1.27.3
FROM debian:bookworm-slim@sha256:734a72b3d6142a71993b4bc580ca01d8ca687f77a2c422d96a961d3376b179bc AS go-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git=1:2.39.5-0+deb12u3 \
    ca-certificates=20250419~deb12u1 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.3@sha256:e519d3b0a5b285e5aa53ab9eef02bc6bbb9cb04608389b743a136a9ce75f0d1e /usr/local/go /usr/local/go

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
FROM ghcr.io/ggml-org/llama.cpp:server-vulkan@sha256:b5f99c093094d54c51e5bb9d79a87f7da28ca7021a7995ce62f769d7e47cc4b9

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
