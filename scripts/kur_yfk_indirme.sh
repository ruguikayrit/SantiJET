#!/usr/bin/env bash
# YFK şartname PDF toplu indirme kurulumu ve çalıştırma
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

echo "==> Eski çıktılar temizleniyor..."
rm -rf yfk_pdfs yfk_sartnameler.zip downloads
echo "==> Bağımlılıklar kuruluyor..."
python3 -m pip install -q -r requirements-yfk.txt

echo "==> PDF'ler indiriliyor / dönüştürülüyor..."
python3 download_yfk_sartnameler.py

echo "==> Paylaşım dosyaları güncelleniyor..."
python3 yfk_download_server.py --publish-only

ZIP="$ROOT/downloads/yfk_sartnameler.zip"
if [[ ! -f "$ZIP" ]]; then
  echo "HATA: ZIP oluşturulamadı: $ZIP" >&2
  exit 1
fi

COUNT="$(python3 - <<'PY'
import zipfile
from pathlib import Path
with zipfile.ZipFile(Path("downloads/yfk_sartnameler.zip")) as zf:
    print(sum(1 for n in zf.namelist() if n.lower().endswith(".pdf")))
PY
)"
BYTES="$(stat -c%s "$ZIP" 2>/dev/null || stat -f%z "$ZIP")"
echo ""
echo "============================================"
echo "  HAZIR"
echo "  ZIP       : $ZIP"
echo "  Dosya     : ${COUNT} PDF"
echo "  Boyut     : $BYTES bayt"
echo "  Web sayfa : file://$ROOT/downloads/index.html"
echo "============================================"
echo ""
echo "Yerel indirme sunucusu için:"
echo "  python3 yfk_download_server.py"
echo ""
