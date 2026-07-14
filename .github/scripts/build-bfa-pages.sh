#!/usr/bin/env bash
# BFA web build for GitHub Pages (/bfa/). Deploy hattında yalnızca build alınır.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_DIR="${ROOT_DIR}/site/bfa"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

mkdir -p "${SITE_DIR}"

pushd "${ROOT_DIR}/artifacts/santijet-bfa-flutter" >/dev/null
flutter pub get
flutter build web --release --base-href "/${REPO_NAME}/bfa/" --pwa-strategy=none
perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

echo "BFA pages ready at ${SITE_DIR}"
