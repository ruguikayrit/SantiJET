#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="$ROOT/web/dwg"
TMP="$(mktemp -d)"

cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

cd "$TMP"
npm pack @mlightcad/libredwg-web >/dev/null
tar -xzf mlightcad-libredwg-web-*.tgz

mkdir -p "$TARGET/wasm"
cp package/dist/libredwg-web.js "$TARGET/libredwg-web.js"
cp package/wasm/libredwg-web.js "$TARGET/wasm/"
cp package/wasm/libredwg-web.wasm "$TARGET/wasm/"

echo "LibreDWG web assets installed under $TARGET"
