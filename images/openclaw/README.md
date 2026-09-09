# `openclaw`

Hardened, autonomous web browsing and automation container built on `openclaw/openclaw` with pre-installed Playwright Chromium headless drivers, Rust Cargo toolchain, and upgraded npm dependency trees to maintain zero CVEs.

---

## 🛠 Features
- **Headless Browser Automation**: Pre-compiled Playwright with Chromium browser binaries and required OS dependencies.
- **Supply Chain Hardening**: Patched node modules (`tar`, `undici`, `nanoid`, `fast-uri`, `adm-zip`, `brace-expansion`) eliminating inherited CVEs.
- **Unprivileged Runtime**: Runs strictly as UID `1000:1000`.

---

## 🚀 Usage

### Docker Run
```bash
docker run -d \
  --name openclaw \
  -p 3000:3000 \
  -v ./data:/app/data \
  ghcr.io/bumuellp/openclaw:latest
```

### Docker Compose
```yaml
services:
  openclaw:
    image: ghcr.io/bumuellp/openclaw:latest
    container_name: openclaw
    restart: unless-stopped
    ports:
      - "3000:3000"
    volumes:
      - ./data:/app/data
```

---

## ⚙️ Specifications
- **Runtime User**: `1000:1000` (non-root).
- **Installed Engines**: Node.js, pnpm, Playwright + Chromium.
