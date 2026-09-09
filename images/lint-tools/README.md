# `lint-tools`

Lightweight, multi-stage DevOps, formatting, and validation container image built on Debian Trixie (13) Slim.

Compiles all Go tools from source with official Go 1.27.1, eliminates Go standard library CVEs, runs as non-root user `appuser` (UID 1000), and provides zero-CVE vulnerability status.

---

## 🛠 Included Toolchains

| Tool | Version / Upstream | License | Purpose |
| :--- | :--- | :--- | :--- |
| **`shfmt`** | v3.14.1 (Go source build) | BSD-3-Clause | Shell script formatter |
| **`shellcheck`** | 0.10.0 (Debian APT) | GPL-3.0 | Shell script static analysis |
| **`kubeconform`** | v0.8.0 (Go source build) | Apache-2.0 | Fast Kubernetes JSONSchema validator |
| **`kube-score`** | v1.20.0 (Go source build) | MIT | Kubernetes manifest best-practice audit |
| **`kustomize`** | v5.8.1 (Go source build) | Apache-2.0 | Kubernetes declarative configuration management |
| **`trivy`** | 0.74.0 | Apache-2.0 | Container and vulnerability security scanner |
| **`trufflehog`** | 3.97.4 | AGPL-3.0 | High-entropy secrets and credential scanner |
| **`yamllint`** | 1.38.0 | GPL-3.0 | YAML syntax and formatting linter |
| **`pre-commit`** | 4.6.2 | MIT | Git multi-language pre-commit runner |
| **`uv`** | 0.12.10+ | Apache-2.0 / MIT | Fast Python dependency and environment manager |
| **`pytest`** | 8.3.5+ | MIT | Python test runner |
| **`ansible`** | ansible-core + ansible-lint | GPL-3.0 | Playbook syntax and linting tool |

---

## 🚀 Usage

### Run Pre-Commit on Workspace
```bash
docker run --rm \
  -v "${PWD}:/workspace" \
  -w /workspace \
  -u "$(id -u):$(id -g)" \
  -e HOME=/tmp \
  -e PRE_COMMIT_HOME=/tmp/pre-commit \
  ghcr.io/bumuellp/lint-tools:latest \
  pre-commit run --all-files
```

### Interactive Shell
```bash
docker run --rm -it \
  -v "${PWD}:/workspace" \
  -w /workspace \
  ghcr.io/bumuellp/lint-tools:latest bash
```

---

## 🔒 Security & User
- **Runtime User**: `appuser` (UID `1000`, GID `1000`).
- **Working Directory**: `/workspace`.
- **Vulnerability Status**: 0 CVEs (Trivy scan enforced in CI).

---

## ⚖️ Open-Source Licenses & Attribution
This image bundles independent command-line tools under various open-source licenses (including AGPL-3.0, GPL-3.0, Apache-2.0, BSD-3-Clause, and MIT). Packaging these tools together constitutes **mere aggregation** under Section 5 of the GPL-3.0 / AGPL-3.0 and does not impose copyleft obligations onto the user's workspace files or other containers.

Upstream licenses and copyright notices are preserved inside the container image at `/usr/local/share/licenses/<tool>/` and `/usr/share/doc/*/copyright`.
