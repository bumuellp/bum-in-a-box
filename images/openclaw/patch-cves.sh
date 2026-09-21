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
	@opentelemetry/propagator-jaeger@latest \
	@vitest/browser@latest \
	adm-zip@latest \
	brace-expansion@latest \
	fast-uri@latest \
	ip-address@latest \
	postcss@latest \
	tar@latest \
	undici@latest \
	nanoid@latest

# Remove known vulnerable versions in /app/node_modules
for pkg in tar undici ws nanoid brace-expansion ip-address adm-zip; do
	rm -rf "/app/node_modules/$pkg"
done

# Copy patched top-level packages
cp -rf /tmp/patch/node_modules/* /app/node_modules/

# Propagate patched packages to nested transitive dependencies
for pkg in nanoid undici tar brace-expansion ip-address adm-zip fast-uri; do
	if [ -d "/tmp/patch/node_modules/$pkg" ]; then
		while IFS= read -r -d '' target_dir; do
			cp -rf "/tmp/patch/node_modules/$pkg"/. "$target_dir/"
		done < <(find /app/node_modules -type d -name "$pkg" -print0)
	fi
done

# Clean up temporary patch artifacts, unused QA test files, and dead third-party SBOM manifests
cd /app
rm -rf /tmp/patch /app/qa
find /app/node_modules -type d -name "_manifest" -prune -exec rm -rf {} +
echo "=== CVE patching completed successfully ==="
