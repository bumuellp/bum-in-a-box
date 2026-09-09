#!/usr/bin/env bash
# ==============================================================================
# Container Image Smoke Test Runner
# Verifies non-root UID execution, binary presence, and basic --version / --help
# ==============================================================================
set -euo pipefail

IMAGE_NAME="${1:-}"
IMAGE_TAG="${2:-latest}"

if [ -z "$IMAGE_NAME" ]; then
	echo "Usage: $0 <image-name> [image-tag]" >&2
	echo "Available images: lint-tools, llama-proxy, mcpo, openclaw, vibe-trading" >&2
	exit 1
fi

FULL_IMAGE="${IMAGE_TAG}"
# If image tag doesn't contain a colon or slash, format standard GHCR reference
if [[ "$IMAGE_TAG" != *":"* ]]; then
	FULL_IMAGE="ghcr.io/bumuellp/${IMAGE_NAME}:${IMAGE_TAG}"
elif [[ "$IMAGE_TAG" != *"/"* ]]; then
	FULL_IMAGE="ghcr.io/bumuellp/${IMAGE_TAG}"
fi

echo "=== Running Smoke Tests on: ${FULL_IMAGE} (${IMAGE_NAME}) ==="

check_non_root() {
	local img="$1"
	local uid
	uid="$(docker run --rm "$img" id -u)"
	if [ "$uid" -eq 0 ]; then
		echo "❌ SECURITY FAILURE: Image $img runs as root (UID 0)!" >&2
		exit 1
	fi
	echo "✓ Non-root UID verified: UID $uid"
}

case "$IMAGE_NAME" in
lint-tools)
	check_non_root "$FULL_IMAGE"
	echo "Verifying lint-tools toolchain..."
	docker run --rm "$FULL_IMAGE" shfmt --version
	docker run --rm "$FULL_IMAGE" shellcheck --version
	docker run --rm "$FULL_IMAGE" kubeconform -v
	docker run --rm "$FULL_IMAGE" kube-score version
	docker run --rm "$FULL_IMAGE" kustomize version
	docker run --rm "$FULL_IMAGE" trivy --version
	docker run --rm "$FULL_IMAGE" trufflehog --version
	docker run --rm "$FULL_IMAGE" yamllint --version
	docker run --rm "$FULL_IMAGE" uv --version
	docker run --rm "$FULL_IMAGE" pre-commit --version
	docker run --rm "$FULL_IMAGE" pytest --version
	echo "✓ All lint-tools binaries verified successfully."
	;;

llama-proxy)
	check_non_root "$FULL_IMAGE"
	echo "Verifying llama-swap binary..."
	docker run --rm --entrypoint /usr/local/bin/llama-swap "$FULL_IMAGE" -h 2>&1 | head -n 5
	echo "✓ llama-proxy entrypoint verified."
	;;

mcpo)
	check_non_root "$FULL_IMAGE"
	echo "Verifying mcpo and uv..."
	docker run --rm --entrypoint mcpo "$FULL_IMAGE" --help 2>&1 | head -n 5
	docker run --rm --entrypoint uv "$FULL_IMAGE" --version
	echo "✓ mcpo runtime verified."
	;;

openclaw)
	check_non_root "$FULL_IMAGE"
	echo "Verifying openclaw non-root user..."
	docker run --rm "$FULL_IMAGE" id
	echo "✓ openclaw container verified."
	;;

vibe-trading)
	check_non_root "$FULL_IMAGE"
	echo "Verifying vibe-trading CLI..."
	docker run --rm "$FULL_IMAGE" vibe-trading --help 2>&1 | head -n 5
	echo "✓ vibe-trading CLI verified."
	;;

*)
	echo "❌ Error: Unknown image name '$IMAGE_NAME'." >&2
	echo "Known images: lint-tools, llama-proxy, mcpo, openclaw, vibe-trading" >&2
	exit 1
	;;
esac

echo "🎉 All smoke tests passed for $IMAGE_NAME ($FULL_IMAGE)!"
