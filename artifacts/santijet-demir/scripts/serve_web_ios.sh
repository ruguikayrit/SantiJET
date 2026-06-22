#!/usr/bin/env bash
# iPhone Safari'den aynı Wi-Fi ağında erişim için web sunucusu.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -d build/web ]]; then
  echo "Web build yok — oluşturuluyor..."
  flutter pub get
  flutter build web --release
fi

IP=$(hostname -I 2>/dev/null | awk '{print $1}')
PORT="${PORT:-8080}"

echo ""
echo "ŞantiJET DEMİR web sunucusu"
echo "  Bilgisayar: http://127.0.0.1:$PORT"
if [[ -n "${IP:-}" ]]; then
  echo "  iPhone (Safari): http://$IP:$PORT"
  echo "  → iPhone ve bilgisayar aynı Wi-Fi'da olmalı"
fi
echo ""

cd build/web
python3 -m http.server "$PORT" --bind 0.0.0.0
