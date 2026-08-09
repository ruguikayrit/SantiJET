#!/usr/bin/env bash
# ŞantiJET Maliyet web build for GitHub Pages (/maliyet/).
# Kaynak: staging branch varsa oradan, yoksa main.
# Klasör adı geçici: artifacts/santijet-bfa-flutter
#
# Script main veya staging-src/.github/scripts altında olabilir; site/ her zaman
# workspace köküne (main checkout) yazılır.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_CANDIDATE="$(cd "${SCRIPT_DIR}/../.." && pwd)"

if [[ "$(basename "${REPO_CANDIDATE}")" == "staging-src" ]]; then
  ROOT_DIR="$(cd "${REPO_CANDIDATE}/.." && pwd)"
  PREFERRED_SOURCE="${REPO_CANDIDATE}/artifacts/santijet-bfa-flutter"
else
  ROOT_DIR="${REPO_CANDIDATE}"
  PREFERRED_SOURCE=""
fi

SITE_DIR="${ROOT_DIR}/site/maliyet"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

SOURCE_DIR=""
if [[ -n "${PREFERRED_SOURCE}" && -d "${PREFERRED_SOURCE}" ]]; then
  SOURCE_DIR="${PREFERRED_SOURCE}"
  echo "Building Maliyet from staging-src (script host)..."
elif [[ -d "${STAGING_SRC}/artifacts/santijet-bfa-flutter" ]]; then
  SOURCE_DIR="${STAGING_SRC}/artifacts/santijet-bfa-flutter"
  echo "Building Maliyet from staging branch..."
elif [[ -d "${ROOT_DIR}/artifacts/santijet-bfa-flutter" ]]; then
  SOURCE_DIR="${ROOT_DIR}/artifacts/santijet-bfa-flutter"
  echo "Building Maliyet from main..."
else
  echo "::warning::Maliyet source missing; skipping /maliyet/."
  exit 0
fi

mkdir -p "${SITE_DIR}"

pushd "${SOURCE_DIR}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${REPO_NAME}/maliyet/" \
  --pwa-strategy=none
perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

# Yalnızca başarılı build sonrası site/maliyet yaz.
rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"
cp -r build/web/. "${SITE_DIR}/"
popd >/dev/null

# Eski /bfa/ yer imleri → /maliyet/
mkdir -p "${ROOT_DIR}/site/bfa"
cat > "${ROOT_DIR}/site/bfa/index.html" <<EOF
<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8">
  <meta http-equiv="refresh" content="0;url=/${REPO_NAME}/maliyet/">
  <link rel="canonical" href="https://ruguikayrit.github.io/${REPO_NAME}/maliyet/">
  <script>location.replace('/${REPO_NAME}/maliyet/' + (location.hash || ''));</script>
  <title>ŞantiJET Maliyet</title>
</head>
<body>
  <p><a href="/${REPO_NAME}/maliyet/">ŞantiJET Maliyet</a> adresine yönlendiriliyorsunuz…</p>
</body>
</html>
EOF

echo "Maliyet pages ready at ${SITE_DIR}"
echo "URL: https://ruguikayrit.github.io/${REPO_NAME}/maliyet/"
