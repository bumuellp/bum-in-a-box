#!/usr/bin/env bash
# ==============================================================================
# OpenClaw Supply-Chain CVE Patching
# Upgrades global toolchains and hotfixes vulnerable nested npm packages
# ==============================================================================
set -euo pipefail

echo "=== Upgrading global npm toolchain and dependencies ==="
npm install -g --force \
	npm@latest \
	pnpm@latest \
	playwright@latest \
	brace-expansion@latest \
	ip-address@latest \
	tar@latest \
	undici@latest \
	nanoid@latest

# Patch npm's internal vendored copies
for pkg in brace-expansion ip-address tar undici; do
	if [ -d "/usr/local/lib/node_modules/$pkg" ]; then
		cp -rf "/usr/local/lib/node_modules/$pkg" /usr/local/lib/node_modules/npm/node_modules/
	fi
done

rm -rf /usr/local/share/corepack

echo "=== Patching application node_modules for CVE remediation ==="
mkdir -p /tmp/patch
cd /tmp/patch

npm install \
	@modelcontextprotocol/client@latest \
	@modelcontextprotocol/sdk@latest \
	@opentelemetry/propagator-jaeger@latest \
	@vitest/browser@latest \
	adm-zip@latest \
	brace-expansion@latest \
	fast-uri@latest \
	ip-address@latest \
	joi@latest \
	postcss@latest \
	source-map-js@latest \
	tar@latest \
	undici@latest \
	nanoid@latest

PATCH_PKGS=(
	adm-zip
	brace-expansion
	fast-uri
	ip-address
	joi
	nanoid
	postcss
	source-map-js
	tar
	undici
	ws
)

# Remove known vulnerable versions in /app/node_modules
for pkg in "${PATCH_PKGS[@]}"; do
	rm -rf "/app/node_modules/$pkg"
done
rm -rf /app/node_modules/@modelcontextprotocol/client /app/node_modules/@modelcontextprotocol/sdk

# Copy patched packages to top-level if present in /tmp/patch
for pkg in "${PATCH_PKGS[@]}"; do
	if [ -d "/tmp/patch/node_modules/$pkg" ]; then
		cp -rf "/tmp/patch/node_modules/$pkg" /app/node_modules/
	fi
done

for pkg in @opentelemetry/propagator-jaeger @vitest/browser @modelcontextprotocol/client @modelcontextprotocol/sdk; do
	if [ -d "/tmp/patch/node_modules/$pkg" ]; then
		mkdir -p "/app/node_modules/$(dirname "$pkg")"
		rm -rf "/app/node_modules/$pkg"
		cp -rf "/tmp/patch/node_modules/$pkg" "/app/node_modules/$pkg"
	fi
done

# Propagate patched packages to nested transitive dependencies
for pkg in nanoid undici tar brace-expansion ip-address adm-zip fast-uri joi source-map-js; do
	if [ -d "/tmp/patch/node_modules/$pkg" ]; then
		while IFS= read -r -d '' target_dir; do
			if [ "$target_dir" != "/app/node_modules/$pkg" ]; then
				cp -rf "/tmp/patch/node_modules/$pkg"/. "$target_dir/"
			fi
		done < <(find /app/node_modules -type d -name "$pkg" -print0)
	fi
done

for pkg in client sdk; do
	if [ -d "/tmp/patch/node_modules/@modelcontextprotocol/$pkg" ]; then
		while IFS= read -r -d '' target_dir; do
			if [ "$target_dir" != "/app/node_modules/@modelcontextprotocol/$pkg" ]; then
				cp -rf "/tmp/patch/node_modules/@modelcontextprotocol/$pkg"/. "$target_dir/"
			fi
		done < <(find /app/node_modules -path "*/@modelcontextprotocol/$pkg" -type d -print0)
	fi
done

# Clean up temporary patch artifacts, unused QA test files, and dead third-party SBOM manifests
cd /app
rm -rf /tmp/patch /app/qa
find /app/node_modules -type d -name "_manifest" -prune -exec rm -rf {} +
echo "=== CVE patching completed successfully ==="
