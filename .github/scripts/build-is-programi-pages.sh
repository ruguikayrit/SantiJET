#!/usr/bin/env bash
# İş Programı web build for GitHub Pages (/is-programi/).
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_candidate="$(cd "${script_dir}/../.." && pwd)"

if [[ "$(basename "${repo_candidate}")" == "staging-src" ]]; then
  root_dir="$(cd "${repo_candidate}/.." && pwd)"
  preferred_source="${repo_candidate}/artifacts/santijet-is-programi"
else
  root_dir="${repo_candidate}"
  preferred_source=""
fi

site_dir="${root_dir}/site/is-programi"
staging_src="${root_dir}/staging-src"
repo_name="${GITHUB_REPOSITORY_NAME:-SantiJET}"

source_dir=""
if [[ -n "${preferred_source}" && -d "${preferred_source}" ]]; then
  source_dir="${preferred_source}"
elif [[ -d "${staging_src}/artifacts/santijet-is-programi" ]]; then
  source_dir="${staging_src}/artifacts/santijet-is-programi"
elif [[ -d "${root_dir}/artifacts/santijet-is-programi" ]]; then
  source_dir="${root_dir}/artifacts/santijet-is-programi"
else
  echo "::error::İş Programı kaynağı bulunamadı."
  exit 1
fi

pushd "${source_dir}" >/dev/null
flutter pub get
flutter build web --release \
  --base-href "/${repo_name}/is-programi/" \
  --pwa-strategy=none
popd >/dev/null

rm -rf "${site_dir}"
mkdir -p "${site_dir}"
cp -R "${source_dir}/build/web/." "${site_dir}/"

echo "ŞantiJET İş Programı Pages çıktısı: ${site_dir}"
echo "URL: https://ruguikayrit.github.io/${repo_name}/is-programi/"
