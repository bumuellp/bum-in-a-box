# `mcpo`

Model Context Protocol (MCP) Orchestrator and REST/SSE bridge container built on Node 24 Slim with integrated Python 3, `pip`, and `uv`.

Bridges multiple standalone MCP servers (CLI, stdio, uvx, and SSE) into a unified HTTP/SSE endpoint, enabling LLM clients and agents to connect to local tools securely.

---

## 🛠 Features
- **Dual Node + Python Ecosystem**: Pre-installed Node.js 24 and Python 3 with `uv` to spawn both npm-based and Python-based MCP servers (e.g. via `uvx`).
- **Pre-installed `mcpo`**: Pinned stable MCP runtime (`mcp>=1.10.1,<2.0.0`) preventing breaking changes.
- **Secure Non-Root Execution**: Runs under default `node` unprivileged user.

---

## 🚀 Usage

### Docker Run
```bash
docker run -d \
  --name mcpo \
  -p 9000:9000 \
  -v ./config.json:/app/config.json:ro \
  ghcr.io/bumuellp/mcpo:latest
```

### Docker Compose
```yaml
services:
  mcpo:
    image: ghcr.io/bumuellp/mcpo:latest
    container_name: mcpo
    restart: unless-stopped
    ports:
      - "9000:9000"
    volumes:
      - ./config.json:/app/config.json:ro
```

---

## ⚙️ Specifications
- **Exposed Port**: `9000`.
- **Default Entrypoint**: `mcpo`.
- **Default Arguments**: `["--config", "/app/config.json", "--port", "9000"]`.
- **Runtime User**: `node` (non-root).
