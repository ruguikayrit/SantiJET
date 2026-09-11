#!/usr/bin/env bash
# DEMİR production kök dosyalarını site/ altına kaydet/geri yükle (alt app klasörlerine dokunmaz).
set -euo pipefail

ROOT="${1:?repo root}"
MODE="${2:?save|restore}"

CACHE="${ROOT}/pages-cache/demir-root"
SITE="${ROOT}/site"

DEMIR_ROOT_ITEMS=(
  index.html
  main.dart.js
  flutter.js
  flutter_bootstrap.js
  flutter_service_worker.js
  version.json
  manifest.json
  favicon.png
  assets
  canvaskit
  icons
  .last_build_id
)

save_demir_root() {
  mkdir -p "${CACHE}"
  find "${CACHE}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
  for item in "${DEMIR_ROOT_ITEMS[@]}"; do
    if [[ -e "${SITE}/${item}" ]]; then
      cp -a "${SITE}/${item}" "${CACHE}/"
    fi
  done
  test -f "${CACHE}/index.html"
}

restore_demir_root() {
  mkdir -p "${SITE}"
  if [[ ! -f "${CACHE}/index.html" ]]; then
    echo "DEMİR root cache missing"
    return 1
  fi
  for item in "${CACHE}"/*; do
    base="$(basename "${item}")"
    rm -rf "${SITE}/${base}"
    cp -a "${item}" "${SITE}/${base}"
  done
}

case "${MODE}" in
  save) save_demir_root ;;
  restore) restore_demir_root ;;
  *)
    echo "Unknown mode: ${MODE}" >&2
    exit 1
    ;;
esac
