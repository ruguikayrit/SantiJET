#!/usr/bin/env bash
# Puantaj web build for GitHub Pages (/puantaj/) — staging önizleme.
# Kaynak: staging branch varsa oradan, yoksa main.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_DIR="${ROOT_DIR}/site/puantaj"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -d "${STAGING_SRC}/artifacts/santijet-puantaj" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-puantaj"
  echo "Building Puantaj from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-puantaj" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-puantaj"
  echo "Building Puantaj from main..."
else
  echo "::warning::Puantaj source missing; skipping /puantaj/."
  exit 0
fi

mkdir -p "${SITE_DIR}"

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/puantaj/" \
  --pwa-strategy=none \
  --dart-define=DEPLOY_CHANNEL=staging

perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

perl -i -pe 's|<body>|<body><div id="santijet-staging-banner" style="position:fixed;top:0;left:0;right:0;z-index:99999;background:#f59e0b;color:#111827;text-align:center;font:600 12px/1.4 system-ui,sans-serif;padding:6px 10px;pointer-events:none;">STAGING ÖNİZLEME — ŞantiJET Puantaj</div><div style="height:28px"></div>|' build/web/index.html

cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "Puantaj pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/puantaj/"
