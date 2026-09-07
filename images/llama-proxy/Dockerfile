# Stage 1: Build latest secure llama-swap binary with official Go 1.27.0 release (0 CVEs)
FROM debian:bookworm-slim AS go-builder

RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install official Go 1.27.1 distribution
RUN TARGETARCH="$(uname -m)" \
    && if [ "$TARGETARCH" = "x86_64" ]; then GOARCH="amd64"; \
       elif [ "$TARGETARCH" = "aarch64" ]; then GOARCH="arm64"; \
       else GOARCH="amd64"; fi \
    && curl -fsSL "https://dl.google.com/go/go1.27.1.linux-${GOARCH}.tar.gz" | tar -C /usr/local -xz

ENV PATH="/usr/local/go/bin:${PATH}"
ENV GOTOOLCHAIN=auto

WORKDIR /src
ARG LLAMA_SWAP_REPO=https://github.com/mostlygeek/llama-swap.git
ARG LLAMA_SWAP_REF=main
ARG CACHEBUST=20260824
RUN /usr/local/go/bin/go version \
    && git clone --depth 1 ${LLAMA_SWAP_REPO} . && git checkout ${LLAMA_SWAP_REF} \
    && CGO_ENABLED=0 go build -ldflags="-s -w" -o /build/llama-swap . \
    && /usr/local/go/bin/go version -m /build/llama-swap

# Stage 2: Official GGML Vulkan runtime (native glibc, OpenSSL 3.3, and Vulkan drivers)
FROM ghcr.io/ggml-org/llama.cpp:server-vulkan

LABEL org.opencontainers.image.title="llama-proxy" \
      org.opencontainers.image.description="llama-swap proxy with native Vulkan llama-server" \
      org.opencontainers.image.source="https://github.com/mostlygeek/llama-swap"

USER root

# Remove unused pebble binary inherited from upstream base image that contains Go stdlib CVEs
RUN rm -f /usr/bin/pebble

# Copy static llama-swap binary from Go builder stage
COPY --from=go-builder /build/llama-swap /usr/local/bin/llama-swap

EXPOSE 5002
ENTRYPOINT ["/usr/local/bin/llama-swap"]

USER 1000:1000
