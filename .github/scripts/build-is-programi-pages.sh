#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
app_dir="$repo_root/artifacts/santijet-is-programi"
deploy_root="${GITHUB_WORKSPACE:-$repo_root}"
output_dir="$deploy_root/site/is-programi"

cd "$app_dir"
flutter pub get
flutter build web --release --base-href /is-programi/

rm -rf "$output_dir"
mkdir -p "$output_dir"
cp -R build/web/. "$output_dir/"

echo "ŞantiJET İş Programı Pages çıktısı: $output_dir"
