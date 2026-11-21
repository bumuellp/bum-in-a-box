#!/usr/bin/env bash
set -euo pipefail

repo="$1"
tag="$2"
name="$3"
subpath="${4:-.}"
shift 4 || true

git clone --depth 1 --branch "$tag" "$repo" "/tmp/$name"
mkdir -p "/out/bin" "/out/share/licenses/$name"
cp "/tmp/$name"/LICENSE* "/out/share/licenses/$name/" 2>/dev/null || true
rm -rf "/tmp/$name/vendor"
if [ "$#" -gt 0 ]; then
    go -C "/tmp/$name/$subpath" get "$@" || true
fi
go -C "/tmp/$name/$subpath" mod tidy
CGO_ENABLED=0 GOWORK=off go -C "/tmp/$name/$subpath" build -mod=mod \
    -ldflags="-s -w ${EXTRA_LDFLAGS:-}" -o "/out/bin/$name" .
rm -rf "/tmp/$name"
