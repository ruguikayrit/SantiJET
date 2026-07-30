#!/usr/bin/env bash
# Beton web build for GitHub Pages (/beton/) — staging önizleme.
# Kaynak: staging branch varsa oradan, yoksa main.
#
# Script main veya staging-src/.github/scripts altında olabilir; site/ her zaman
# workspace köküne (main checkout) yazılır.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CANDIDATE="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(basename "${REPO_CANDIDATE}")" == "staging-src" ]]; then
  ROOT_DIR="$(cd "${REPO_CANDIDATE}/.." && pwd)"
  PREFERRED_SOURCE="${REPO_CANDIDATE}/artifacts/santijet-beton"
else
  ROOT_DIR="${REPO_CANDIDATE}"
  PREFERRED_SOURCE=""
fi

SITE_DIR="${ROOT_DIR}/site/beton"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -n "${PREFERRED_SOURCE}" && -d "${PREFERRED_SOURCE}" ]]; then
  SOURCE_DIR="${PREFERRED_SOURCE}"
  echo "Building Beton from staging-src (script host)..."
elif [[ -d "${STAGING_SRC}/artifacts/santijet-beton" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-beton"
  echo "Building Beton from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-beton" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-beton"
  echo "Building Beton from main..."
else
  echo "::warning::Beton source missing; skipping /beton/."
  exit 0
fi

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/beton/" \
  --pwa-strategy=none \
  --dart-define=DEPLOY_CHANNEL=staging

perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

perl -i -pe 's|<body([^>]*)>|<body$1><div id="santijet-staging-banner" style="position:fixed;top:0;left:0;right:0;z-index:99999;background:#f59e0b;color:#111827;text-align:center;font:600 12px/1.4 system-ui,sans-serif;padding:6px 10px;pointer-events:none;">STAGING ÖNİZLEME — ŞantiJET Beton</div><div style="height:28px"></div>|' build/web/index.html

# Yalnızca başarılı build sonrası site/beton yaz (boş klasör → 404 olmasın).
rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "Beton pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/beton/"
