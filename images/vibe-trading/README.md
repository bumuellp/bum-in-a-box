# `vibe-trading`

Multi-stage container packaging for **HKUDS Vibe-Trading**: an AI-driven finance research and quantitative trading agent with natural language backtesting capabilities.

Combines a compiled Vue/Vite Web UI frontend with a hardened Python 3.11 runtime, Pango/Cairo rendering libraries, and built-in HTTP health probes.

---

## 🛠 Features
- **Integrated Full-Stack**: Single container bundling static frontend UI and FastAPI/Python agent backend.
- **Graphic Rendering Libraries**: Includes `pango`, `cairo`, `harfbuzz`, and `dejavu-fonts` for financial charting and PDF report generation.
- **Built-in Healthcheck**: Automatic HTTP health probing on `/live`.
- **Sandbox User Isolation**: Dedicated unprivileged `vibe` user and system `vibe-sandbox` UID for code execution.

---

## 🚀 Usage

### Docker Run
```bash
docker run -d \
  --name vibe-trading \
  -p 8899:8899 \
  -v ./data:/home/vibe/.vibe-trading \
  -e OPENAI_API_BASE=http://llama-proxy:5002/v1 \
  -e OPENAI_API_KEY=not-needed \
  ghcr.io/bumuellp/vibe-trading:latest
```

### Docker Compose
```yaml
services:
  vibe-trading:
    image: ghcr.io/bumuellp/vibe-trading:latest
    container_name: vibe-trading
    restart: unless-stopped
    ports:
      - "8899:8899"
    environment:
      - OPENAI_API_BASE=http://llama-proxy:5002/v1
      - OPENAI_API_KEY=not-needed
    volumes:
      - ./data:/home/vibe/.vibe-trading
```

---

## ⚙️ Specifications
- **Exposed Port**: `8899` (Web UI & REST API).
- **Default Command**: `vibe-trading serve --host 0.0.0.0 --port 8899`.
- **Health Check**: `http://localhost:8899/live`.
- **Runtime User**: `vibe` (non-root).
