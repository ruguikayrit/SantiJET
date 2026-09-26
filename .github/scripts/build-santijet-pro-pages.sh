#!/usr/bin/env bash
# ŞantiJET Pro kabuk — GitHub Pages (/santijet-pro/).
# Kilitli /pro/ hub’ı (santijet-ana) değiştirilmez.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CANDIDATE="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(basename "${REPO_CANDIDATE}")" == "staging-src" ]]; then
  ROOT_DIR="$(cd "${REPO_CANDIDATE}/.." && pwd)"
  PREFERRED_SOURCE="${REPO_CANDIDATE}/artifacts/santijet-pro"
else
  ROOT_DIR="${REPO_CANDIDATE}"
  PREFERRED_SOURCE=""
fi

SITE_DIR="${ROOT_DIR}/site/santijet-pro"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -n "${PREFERRED_SOURCE}" && -d "${PREFERRED_SOURCE}" ]]; then
  SOURCE_DIR="${PREFERRED_SOURCE}"
  echo "Building ŞantiJET Pro from staging-src (script host)..."
elif [[ -d "${STAGING_SRC}/artifacts/santijet-pro" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-pro"
  echo "Building ŞantiJET Pro from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-pro" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-pro"
  echo "Building ŞantiJET Pro from main..."
else
  echo "::error::ŞantiJET Pro kaynağı bulunamadı."
  exit 1
fi

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/santijet-pro/" \
  --pwa-strategy=none \
  --dart-define=DEPLOY_CHANNEL=staging

# Turuncu staging şeridi ve flutter-view kaydırması yok.
rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "ŞantiJET Pro pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/santijet-pro/"
