#!/usr/bin/env bash
# Tahvil web build for GitHub Pages (/tahvil/) — staging önizleme.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CANDIDATE="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(basename "${REPO_CANDIDATE}")" == "staging-src" ]]; then
  ROOT_DIR="$(cd "${REPO_CANDIDATE}/.." && pwd)"
  PREFERRED_SOURCE="${REPO_CANDIDATE}/artifacts/santijet-tahvil"
else
  ROOT_DIR="${REPO_CANDIDATE}"
  PREFERRED_SOURCE=""
fi

SITE_DIR="${ROOT_DIR}/site/tahvil"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -n "${PREFERRED_SOURCE}" && -d "${PREFERRED_SOURCE}" ]]; then
  SOURCE_DIR="${PREFERRED_SOURCE}"
  echo "Building Tahvil from staging-src (script host)..."
elif [[ -d "${STAGING_SRC}/artifacts/santijet-tahvil" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-tahvil"
  echo "Building Tahvil from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-tahvil" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-tahvil"
  echo "Building Tahvil from main..."
else
  echo "::warning::Tahvil source missing; skipping /tahvil/."
  exit 0
fi

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/tahvil/" \
  --pwa-strategy=none \
  --dart-define=DEPLOY_CHANNEL=staging

perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

perl -i -pe 's|<body([^>]*)>|<body$1><div id="santijet-staging-banner" style="position:fixed;top:0;left:0;right:0;z-index:99999;background:#f59e0b;color:#111827;text-align:center;font:600 12px/1.4 system-ui,sans-serif;padding:6px 10px;pointer-events:none;">STAGING ÖNİZLEME — ŞantiJET Tahvil</div><div style="height:28px"></div>|' build/web/index.html

rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "Tahvil pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/tahvil/"
