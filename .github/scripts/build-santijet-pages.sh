#!/usr/bin/env bash
# GitHub Pages — DEMİR production (main) + DEMİR staging önizleme (/staging/)
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SITE_DIR="${ROOT_DIR}/site"
MAIN_SRC="${ROOT_DIR}"
STAGING_SRC="${ROOT_DIR}/staging-src"
REPO_NAME="${GITHUB_REPOSITORY_NAME:-SantiJET}"

rm -rf "${SITE_DIR}"
mkdir -p "${SITE_DIR}"

normalize_supabase_url() {
  local raw="$1"
  local clean="${raw%/}"
  clean="${clean%/rest/v1}"
  clean="${clean%/auth/v1}"
  clean="${clean%/storage/v1}"
  clean="${clean%/functions/v1}"
  printf '%s' "${clean}"
}

install_libredwg_web() {
  local source_dir="$1"
  local setup="${source_dir}/artifacts/santijet-demir/scripts/setup-libredwg-web.sh"

  if [[ ! -f "${setup}" ]]; then
    echo "::warning::LibreDWG setup script missing at ${setup}"
    return 0
  fi

  echo "Installing LibreDWG web assets for ${source_dir}..."
  bash "${setup}"
}

build_demir_web() {
  local source_dir="$1"
  local output_subpath="$2"
  local channel_label="$3"
  local base_href="/${REPO_NAME}/"
  local output_dir="${SITE_DIR}"

  if [[ -n "${output_subpath}" ]]; then
    base_href="/${REPO_NAME}/${output_subpath}/"
    output_dir="${SITE_DIR}/${output_subpath}"
  fi

  mkdir -p "${output_dir}"
  install_libredwg_web "${source_dir}"

  pushd "${source_dir}/artifacts/santijet-demir" >/dev/null
  flutter pub get

  local dart_defines=()
  if [[ -n "${SUPABASE_URL:-}" && -n "${SUPABASE_ANON_KEY:-}" ]]; then
    local clean_url
    clean_url="$(normalize_supabase_url "${SUPABASE_URL}")"
    dart_defines+=( "--dart-define=SUPABASE_URL=${clean_url}" )
    dart_defines+=( "--dart-define=SUPABASE_ANON_KEY=${SUPABASE_ANON_KEY}" )
  fi
  dart_defines+=( "--dart-define=DEPLOY_CHANNEL=${channel_label}" )

  flutter build web --release --base-href "${base_href}" --pwa-strategy=none "${dart_defines[@]}"
  perl -i -0pe 's/_flutter\.loader\.load\(\{\s*serviceWorkerSettings:\s*\{[^}]+\}\s*\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/s' build/web/flutter_bootstrap.js
  perl -i -pe 's/_flutter\.loader\.load\(\{\}\);/window.__SANTIJET_START_FLUTTER__&&window.__SANTIJET_START_FLUTTER__();/g' build/web/flutter_bootstrap.js

  if [[ "${channel_label}" == "staging" ]]; then
    perl -i -pe 's|<body>|<body><div id="santijet-staging-banner" style="position:fixed;top:0;left:0;right:0;z-index:99999;background:#f59e0b;color:#111827;text-align:center;font:600 12px/1.4 system-ui,sans-serif;padding:6px 10px;pointer-events:none;">STAGING ÖNİZLEME — canlı sürüm değil</div><div style="height:28px"></div>|' build/web/index.html
  fi

  cp -r build/web/. "${output_dir}/"
  popd >/dev/null
}

echo "Building production DEMİR from main..."
build_demir_web "${MAIN_SRC}" "" "production"

if [[ -d "${STAGING_SRC}/artifacts/santijet-demir" ]]; then
  echo "Building staging DEMİR preview..."
  build_demir_web "${STAGING_SRC}" "staging" "staging"
else
  echo "Staging source missing; skipping /staging preview."
fi

echo "DEMİR pages ready under ${SITE_DIR}"
