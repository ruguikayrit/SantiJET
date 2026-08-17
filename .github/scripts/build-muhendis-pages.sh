#!/usr/bin/env bash
# Mühendis web build for GitHub Pages (/muhendis/) — staging önizleme.
# Kaynak: staging branch varsa oradan, yoksa main.
#
# Script main veya staging-src/.github/scripts altında olabilir; site/ her zaman
# workspace köküne (main checkout) yazılır.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CANDIDATE="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(basename "${REPO_CANDIDATE}")" == "staging-src" ]]; then
  ROOT_DIR="$(cd "${REPO_CANDIDATE}/.." && pwd)"
  PREFERRED_SOURCE="${REPO_CANDIDATE}/artifacts/santijet-muhendis"
else
  ROOT_DIR="${REPO_CANDIDATE}"
  PREFERRED_SOURCE=""
fi

SITE_DIR="${ROOT_DIR}/site/muhendis"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -n "${PREFERRED_SOURCE}" && -d "${PREFERRED_SOURCE}" ]]; then
  SOURCE_DIR="${PREFERRED_SOURCE}"
  echo "Building Mühendis from staging-src (script host)..."
elif [[ -d "${STAGING_SRC}/artifacts/santijet-muhendis" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-muhendis"
  echo "Building Mühendis from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-muhendis" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-muhendis"
  echo "Building Mühendis from main..."
else
  echo "::warning::Mühendis source missing; skipping /muhendis/."
  exit 0
fi

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/muhendis/" \
  --pwa-strategy=none \
  --dart-define=DEPLOY_CHANNEL=staging

perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

# Staging’de turuncu #santijet-staging-banner, 28px spacer ve
# flutter-view / flt-glass-pane { top:28px } enjekte etme (Demir/Tahvil kurgu).

# Yalnızca başarılı build sonrası site/muhendis yaz (boş klasör → 404 olmasın).
rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "Mühendis pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/muhendis/"
