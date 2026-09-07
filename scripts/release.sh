#!/usr/bin/env bash
# ==============================================================================
# Release Management Helper for bum-in-a-box
# Ensures strict SemVer versioning (e.g. v1.0.1) and safe GitHub Release creation.
# ==============================================================================
set -euo pipefail

TARGET_TAG="${1:-}"

if [ -z "$TARGET_TAG" ]; then
	echo "Usage: ./scripts/release.sh <vX.Y.Z>"
	echo "Example: ./scripts/release.sh v1.0.1"
	exit 1
fi

# 1. Validate Semantic Versioning format (vX.Y.Z)
SEMVER_REGEX="^v[0-9]+\.[0-9]+\.[0-9]+$"
if [[ ! "$TARGET_TAG" =~ $SEMVER_REGEX ]]; then
	echo "ERROR: Invalid tag format '$TARGET_TAG'."
	echo "Release tags must follow strict SemVer with 'v' prefix (e.g., v1.0.0, v1.0.1, v1.2.0)."
	exit 1
fi

# 2. Verify git working directory is clean
if [ -n "$(git status --porcelain)" ]; then
	echo "ERROR: Working tree is dirty. Please commit or stash changes before releasing."
	exit 1
fi

# 3. Verify current branch is main
CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"
if [ "$CURRENT_BRANCH" != "main" ]; then
	echo "ERROR: Releases must be cut from 'main' branch (current: '$CURRENT_BRANCH')."
	exit 1
fi

# 4. Check if tag already exists locally or remotely
if git rev-parse "$TARGET_TAG" >/dev/null 2>&1; then
	echo "ERROR: Tag '$TARGET_TAG' already exists locally."
	exit 1
fi

if git ls-remote --tags origin "$TARGET_TAG" | grep -q "$TARGET_TAG"; then
	echo "ERROR: Tag '$TARGET_TAG' already exists on remote origin. Release tags are immutable!"
	exit 1
fi

echo "========================================================"
echo " Creating Immutable Release: $TARGET_TAG"
echo " Target branch: $CURRENT_BRANCH ($(git rev-parse --short HEAD))"
echo "========================================================"

# 5. Create and publish GitHub Release
gh release create "$TARGET_TAG" \
	--title "$TARGET_TAG" \
	--generate-notes \
	--target main

echo ""
echo " Release '$TARGET_TAG' published successfully!"
echo " GitHub Actions release workflow has been triggered to publish immutable OCI images to GHCR."
