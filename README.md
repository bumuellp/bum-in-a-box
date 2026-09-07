# bum-in-a-box

A curated collection of production-hardened OCI container images and specialized execution environments for DevOps pipelines, AI agent stacks, local LLM gateways, and homelab infrastructure.

---

## 📦 Container Catalog & Architecture

### 1. `llama-proxy` — High-Speed Vulkan LLM Gateway & Dynamic Model Switcher
A high-performance reverse proxy and OpenAI-compatible API gateway combining [`mostlygeek/llama-swap`](https://github.com/mostlygeek/llama-swap) with GGML's official native Vulkan `llama-server`.

* **Image:** `ghcr.io/bumuellp/llama-proxy:latest` (also `:v1`, `:v1.0.0`)
* **Base Runtime:** `ghcr.io/ggml-org/llama.cpp:server-vulkan`
* **Default Port:** `5002`
* **Key Features & Differentiators:**
  * **Dynamic Model Hot-Swapping (`llama-swap`):** Automatically routes incoming inference requests to the appropriate GGUF model, dynamically launching and unloading backend `llama-server` instances to reclaim GPU VRAM.
  * **`ktransforms` Support:** In-flight request and response transformations, prompt rewrite pipelines, model alias mapping, and speculative decoding routing (MTP).
  * **Official Go 1.27 Build Stage:** Built from source using the official Go 1.27 distribution for a clean, static, zero-CVE binary.
  * **Hardened Base:** Strips unused upstream binaries (such as `pebble` containing Go stdlib CVEs) while retaining native Vulkan drivers, glibc, and OpenSSL 3.3.
  * **Non-Root Execution:** Runs as UID/GID `1000:1000` with host IPC and GPU device passthrough (`/dev/kfd`, `/dev/dri`).

#### Usage:
```bash
docker run -d \
  --name llama-proxy \
  -p 5002:5002 \
  --device /dev/kfd \
  --device /dev/dri \
  -v /path/to/models:/models:ro \
  -v /var/run/docker.sock:/var/run/docker.sock \
  ghcr.io/bumuellp/llama-proxy:latest \
  --listen 0.0.0.0:5002 --config /models/models.yaml
```

---

### 2. `mcpo` — Model Context Protocol Gateway & `uvx` Bridge
An HTTP/OpenAPI proxy and orchestration server providing unified REST endpoints to CLI-based and STDIO Model Context Protocol (MCP) servers.

* **Image:** `ghcr.io/bumuellp/mcpo:latest` (also `:v1`, `:v1.0.0`)
* **Base Runtime:** `node:24-slim` with Python 3, `pip`, and `uv`
* **Default Port:** `9000`
* **Why it differs from upstream:**
  * **Built-in Python & `uv` Runtime:** Standard Node MCP images fail when executing MCP tools that spawn themselves using `uvx`. This image bundles `uv` out-of-the-box.
  * **Pinned Protocol Stability:** Pins `mcp>=1.10.1,<2.0.0` to ensure stability against breaking spec transitions.
  * **Supply-Chain Hardening:** Upstream Node packages are explicitly patched (`tar@latest`, `brace-expansion@latest`, `ip-address@latest`) to eliminate supply-chain vulnerabilities.

#### Usage:
```bash
docker run -d \
  --name mcpo \
  -p 9000:9000 \
  -v /path/to/config.json:/app/config.json:ro \
  ghcr.io/bumuellp/mcpo:latest \
  --config /app/config.json --port 9000
```

---

### 3. `lint-tools` — Unified DevOps, Linting & Secrets Toolchain
A complete static analysis, policy validation, Kubernetes scoring, and secrets scanning container.

* **Image:** `ghcr.io/bumuellp/lint-tools:latest` (also `:v1`, `:v1.0.0`)
* **Base Runtime:** `debian:trixie-slim`
* **Pre-installed Tools:**
  * **Secrets & CVEs:** `trufflehog` (v3.97.4), `trivy` (v0.74.0)
  * **Kubernetes:** `kubeconform` (v0.8.0), `kube-score` (v1.20.0), `kustomize` (v5.8.1)
  * **Shell:** `shellcheck`, `shfmt` (v3.14.1)
  * **YAML & XML:** `yamllint`, `libxml2-utils` (`xmllint`)
  * **Ansible & Python:** `ansible-core`, `ansible-lint`, `pytest`, `python3`, `pip`
  * **Git Hooks:** `pre-commit`
* **Why it differs from generic images:** Single multi-stage image combining Go binaries, Python runtime, and shell tools under a non-root user (`appuser:1000`) with pre-configured writable cache directories (`/tmp/pre-commit`, `/tmp/ansible`).

#### Usage:
```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/bumuellp/lint-tools:latest pre-commit run --all-files
```

---

### 4. `vibe-trading` — Quantitative AI Finance Agent & Backtesting Stack
Natural-language quantitative finance research and AI agent stack with integrated backtesting engine and React web interface.

* **Image:** `ghcr.io/bumuellp/vibe-trading:latest` (also `:v1`, `:v1.0.0`)
* **Upstream:** [HKUDS/Vibe-Trading](https://github.com/HKUDS/Vibe-Trading)
* **Default Port:** `8899`
* **Why it differs from upstream:**
  * **Self-Contained Multi-Stage Build:** Compiles the Vite/React frontend (`frontend/dist`) and Python 3.11 virtualenv with required native rendering libraries (`libpango`, `libcairo`, `libharfbuzz`, fonts).
  * **Dual-User Sandboxing:** Runs primary web services under non-root user `vibe` with an isolated system user (`vibe-sandbox`, UID `10001`) for safe script execution.
  * **Health Probes:** Includes built-in `/live` health check endpoint for Kubernetes / Podman orchestrators.

#### Usage:
```bash
docker run -d \
  --name vibe-trading \
  -p 8899:8899 \
  -v vibe_data:/home/vibe/.vibe-trading \
  ghcr.io/bumuellp/vibe-trading:latest
```

---

### 5. `openclaw` — Headless Browser Navigation & Agent Execution Stack
Autonomous web navigation and tool execution agent runtime.

* **Image:** `ghcr.io/bumuellp/openclaw:latest` (also `:v1`, `:v1.0.0`)
* **Default Port:** `8080`
* **Why it differs from upstream:**
  * **Full Headless Chromium Stack:** Installs Playwright system dependencies and Chromium browser runtime directly in the container.
  * **Deep Dependency Supply-Chain Patching:** Recursively patches nested Node dependencies (`adm-zip`, `tar`, `undici`, `nanoid`, `fast-uri`) across `/app/node_modules`.
  * **Non-Root Execution:** UID/GID `1000:1000`.

#### Usage:
```bash
docker run -d \
  --name openclaw \
  -p 8080:8080 \
  ghcr.io/bumuellp/openclaw:latest
```

---

## 🏷️ Versioning & Tagging Convention

All container images follow semantic release tagging:
* `latest`: The latest stable build from the `main` branch.
* `v1`: Major release line track.
* `v1.0.0`: Exact immutable release tag.
* `<sha>`: Commit SHA hash for deterministic tracking and rollbacks.

