# bum-in-a-box

A curated collection of production-hardened OCI container images and specialized execution environments for DevOps pipelines, AI agent stacks, local LLM gateways, and homelab infrastructure.

## 📦 Container Catalog & Architecture

| Container Image | Primary Runtime | Docs | Default Port | Description |
| :--- | :--- | :---: | :---: | :--- |
| **`lint-tools`** | Debian Trixie + Go + Python | [Read Docs](images/lint-tools/README.md) | — | Unified linting, formatting, K8s scoring & secrets toolchain. |
| **`llama-proxy`** | Vulkan GGML + llama-swap | [Read Docs](images/llama-proxy/README.md) | `5002` | High-speed LLM gateway with `ktransforms` & dynamic model swapping. |
| **`mcpo`** | Node 24 Slim + Python + uv | [Read Docs](images/mcpo/README.md) | `9000` | Model Context Protocol gateway & `uvx` runner bridge. |
| **`openclaw`** | Node + Playwright Chromium | [Read Docs](images/openclaw/README.md) | `3000` | Hardened autonomous web browsing and agent execution stack. |
| **`vibe-trading`** | Python 3.11 + Vite/Vue | [Read Docs](images/vibe-trading/README.md) | `8899` | Quantitative finance research & backtesting AI agent stack. |

---

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

## 🧪 Container Smoke Testing
All images are verified using `./scripts/smoke-test.sh` to ensure:
1. **Security Isolation**: Container executes as a non-root UID (`id -u != 0`).
2. **Binary Availability**: Core binaries exist and execute cleanly.
3. **Entrypoint Readiness**: CLI `--version` and `--help` flags respond without runtime crashing.

```bash
# Smoke test an image locally or from GHCR:
./scripts/smoke-test.sh lint-tools ghcr.io/bumuellp/lint-tools:latest
./scripts/smoke-test.sh llama-proxy ghcr.io/bumuellp/llama-proxy:latest
./scripts/smoke-test.sh mcpo ghcr.io/bumuellp/mcpo:latest
```

---

## 🏷️ Versioning & Release Model

Images published to GitHub Packages (GHCR) adhere to standard semantic versioning:
* **`:latest`**: Floating tag tracking the most recent build from `main`.
* **`:<sha>`**: Immutable commit SHA hash for deterministic tracking and rollbacks.
* **`:v1`**: Floating major version tag tracking the active `v1.x` release stream.
* **`:v1.0.0`, `:v1.0.1`**: Exact immutable release tags published when an official GitHub Release is published.

---

## 🚀 Creating a New Immutable Release

To cut a new immutable SemVer release (e.g., `v1.0.1`):

```bash
# 1. Ensure main branch is up to date and clean
git checkout main && git pull origin main

# 2. Run the release helper to validate SemVer format and create the GitHub Release
./scripts/release.sh v1.0.1
```

This will:
1. Validate strict SemVer formatting (`vX.Y.Z`).
2. Verify git status and check for tag collision on remote.
3. Automatically generate release notes and publish the GitHub Release.
4. Trigger the GitHub Actions release workflow to build all images, publish the immutable `:v1.0.1` tag, and fast-forward the floating `:v1` pointer.

---

## ⚖️ License & Open-Source Compliance

### Repository Licensing
The Dockerfiles, build scripts, GitHub Actions workflows, and documentation in this repository are licensed under the [MIT License](LICENSE) © 2026 Patrick Bumüller.

### Container Image Composition & Upstream Licenses
The container images built from this repository bundle independent third-party open-source components. Packaging these standalone tools into container images constitutes **mere aggregation** (under GPL-3.0 / AGPL-3.0 Section 5), and does not extend copyleft licensing to unrelated containers or host systems.

All third-party tools retain their respective upstream licenses. Upstream license texts and copyright notices are preserved in `/usr/local/share/licenses/<tool>/` (or `/usr/share/doc/*/copyright` for Debian packages) within each container image:

| Image | Bundled Upstream Components | Licenses |
| :--- | :--- | :--- |
| **`lint-tools`** | `trufflehog`<br>`shellcheck`, `yamllint`, `ansible-core`, `ansible-lint`<br>`kubeconform`, `kustomize`, `trivy`, `uv`<br>`shfmt`<br>`kube-score`, `pre-commit`, `pytest` | **AGPL-3.0**<br>**GPL-3.0**<br>**Apache-2.0**<br>**BSD-3-Clause**<br>**MIT** |
| **`llama-proxy`** | `llama-swap`<br>`llama-server` (GGML Vulkan) | **MIT**<br>**MIT** |
| **`mcpo`** | `mcpo`, `mcp`<br>`uv` | **MIT**<br>**Apache-2.0 / MIT** |
| **`openclaw`** | `openclaw`<br>Playwright, Chromium | **MIT**<br>**Apache-2.0**, BSD |
| **`vibe-trading`** | `HKUDS/Vibe-Trading`<br>Cairo, Pango, HarfBuzz | **MIT**<br>LGPL-2.1 / MPL-2.0 |
