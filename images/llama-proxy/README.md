# `llama-proxy`

High-performance LLM model proxy integrating **llama-swap** with native Vulkan GPU acceleration from **llama.cpp** and advanced **ktransforms** support.

Dynamically loads, swaps, and routes inference requests between multiple local GGUF models on demand, drastically reducing GPU VRAM consumption while providing OpenAI-compatible API endpoints.

---

## ⚡ Key Capabilities & `ktransforms` Support

* **On-Demand Engine Swapping**: Spawns and terminates inference engines on the fly based on incoming requests, keeping idle VRAM footprint at near zero.
* **`ktransforms` Pipeline**:
  * **In-Flight Transformations**: Request and response rewriting pipelines, token sanitation, and header forwarding.
  * **Model Alias & Routing**: Virtual model names mapped to specific quantization quants or specialized weights.
  * **Speculative Decoding & MTP Routing**: Multi-Token Prediction (MTP) routing and draft model pipelines.
* **Large MoE / `ktransformers` Orchestration**: Capable of orchestrating containerized engines (e.g., `ktransformers` for DeepSeek-R1/V3 671B MoE CPU/GPU offload) via mounted rootless Podman/Docker sockets.
* **Hardware Acceleration**: Native Vulkan backend via GGML runtime (Intel Arc, AMD ROCm/RADV, NVIDIA).

---

## 🚀 Usage

### Docker Run
```bash
docker run -d \
  --name llama-proxy \
  -p 5002:5002 \
  -v /var/models:/models:ro \
  -v ./config.yaml:/app/config.yaml:ro \
  --device /dev/dri \
  ghcr.io/bumuellp/llama-proxy:latest \
  -config /app/config.yaml
```

### Docker Compose
```yaml
services:
  llama-proxy:
    image: ghcr.io/bumuellp/llama-proxy:latest
    container_name: llama-proxy
    restart: unless-stopped
    ports:
      - "5002:5002"
    volumes:
      - /mnt/storage/models:/models:ro
      - ./config.yaml:/app/config.yaml:ro
      # Optional: mount container socket to spawn on-demand ktransformers engines
      # - /run/user/1000/podman/podman.sock:/var/run/docker.sock:ro
    devices:
      - /dev/dri:/dev/dri # Vulkan / GPU hardware acceleration
    command: ["-config", "/app/config.yaml"]
```

---

## ⚙️ Specifications & Ports
- **Exposed Port**: `5002` (OpenAI-compatible HTTP API).
- **Default Entrypoint**: `/usr/local/bin/llama-swap`.
- **Runtime User**: Non-root `1000:1000`.
- **Base Runtime**: `ghcr.io/ggml-org/llama.cpp:server-vulkan`.
