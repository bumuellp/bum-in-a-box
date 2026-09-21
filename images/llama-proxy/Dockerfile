# Stage 1: Build llama-swap binary with official Go 1.27.1
FROM debian:bookworm-slim AS go-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    ca-certificates \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

COPY --from=golang:1.27.1 /usr/local/go /usr/local/go

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOTOOLCHAIN=auto

WORKDIR /src
ARG LLAMA_SWAP_REPO=https://github.com/mostlygeek/llama-swap.git
ARG LLAMA_SWAP_REF=main
ARG CACHEBUST=20260824
RUN /usr/local/go/bin/go version \
    && git clone --depth 1 ${LLAMA_SWAP_REPO} . && git checkout ${LLAMA_SWAP_REF} \
    && mkdir -p /build/licenses/llama-swap \
    && cp LICENSE* /build/licenses/llama-swap/ 2>/dev/null || true \
    && CGO_ENABLED=0 go build -ldflags="-s -w" -o /build/llama-swap . \
    && /usr/local/go/bin/go version -m /build/llama-swap

# Stage 2: Official GGML Vulkan runtime (native glibc, OpenSSL 3.3, and Vulkan drivers)
FROM ghcr.io/ggml-org/llama.cpp:server-vulkan

LABEL org.opencontainers.image.title="llama-proxy" \
      org.opencontainers.image.description="llama-swap proxy with native Vulkan llama-server" \
      org.opencontainers.image.source="https://github.com/bumuellp/bum-in-a-box" \
      org.opencontainers.image.upstream="https://github.com/mostlygeek/llama-swap"

USER root

# Remove unused pebble binary inherited from upstream base image that contains Go stdlib CVEs
RUN rm -f /usr/bin/pebble

# Copy static llama-swap binary and license from Go builder stage
COPY --from=go-builder /build/llama-swap /usr/local/bin/llama-swap
COPY --from=go-builder /build/licenses/ /usr/local/share/licenses/

EXPOSE 5002
ENTRYPOINT ["/usr/local/bin/llama-swap"]

USER 1000:1000
