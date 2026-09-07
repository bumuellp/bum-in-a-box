# bum-in-a-box

Container images and base environments for DevOps workflows, CI pipelines, and homelab services.

---

## 📦 Container Catalog

### `lint-tools`
Lightweight multi-tool DevOps, static analysis, and secrets scanning container built on `debian:trixie-slim`.

* **Image:** `ghcr.io/bumuellp/lint-tools:latest`
* **Pre-installed Tools:**
  * **Secrets:** `trufflehog` (v3.97.4)
  * **Vulnerabilities & Auditing:** `trivy` (v0.74.0)
  * **Kubernetes:** `kubeconform` (v0.8.0), `kube-score` (v1.20.0), `kustomize` (v5.8.1)
  * **Shell:** `shellcheck`, `shfmt` (v3.14.1)
  * **YAML & XML:** `yamllint`, `libxml2-utils` (`xmllint`)
  * **Ansible & Python:** `ansible-core`, `ansible-lint`, `pytest`, `python3`
  * **Git Hooks:** `pre-commit`

#### Usage:
```bash
docker run --rm -v "$(pwd):/workspace" -w /workspace ghcr.io/bumuellp/lint-tools:latest pre-commit run --all-files
```
