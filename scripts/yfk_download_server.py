#!/usr/bin/env python3
"""YFK şartname ZIP dosyası için yerel indirme sunucusu ve index sayfası."""

from __future__ import annotations

import argparse
import html
import http.server
import json
import shutil
import socket
from datetime import UTC, datetime
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
DOWNLOADS_DIR = SCRIPT_DIR / "downloads"
ZIP_NAME = "yfk_sartnameler.zip"
PDF_DIR = SCRIPT_DIR / "yfk_pdfs"
DEFAULT_PORT = 8787


def publish_artifacts() -> Path:
    DOWNLOADS_DIR.mkdir(parents=True, exist_ok=True)

    source_zip = SCRIPT_DIR / ZIP_NAME
    if not source_zip.exists():
        raise FileNotFoundError(f"ZIP bulunamadı: {source_zip}. Önce download_yfk_sartnameler.py çalıştırın.")

    target_zip = DOWNLOADS_DIR / ZIP_NAME
    shutil.copy2(source_zip, target_zip)

    manifest_pdfs: list[dict[str, str | int]] = []
    pdf_source = PDF_DIR if PDF_DIR.exists() else None
    if pdf_source:
        for pdf in sorted(pdf_source.glob("*.pdf")):
            dest = DOWNLOADS_DIR / pdf.name
            shutil.copy2(pdf, dest)
            manifest_pdfs.append(
                {
                    "name": pdf.name,
                    "url": pdf.name,
                    "bytes": dest.stat().st_size,
                }
            )

    generated_at = datetime.now(UTC).strftime("%Y-%m-%d %H:%M UTC")
    zip_bytes = target_zip.stat().st_size

    index_html = f"""<!DOCTYPE html>
<html lang="tr">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>YFK Şartnameler — Toplu İndirme</title>
  <style>
    body {{ font-family: system-ui, sans-serif; max-width: 720px; margin: 40px auto; padding: 0 16px; color: #111; }}
    h1 {{ font-size: 1.4rem; }}
    .btn {{
      display: inline-block; background: #16213e; color: #fff; text-decoration: none;
      padding: 14px 22px; border-radius: 8px; font-weight: 600; margin: 12px 0 20px;
    }}
    .btn:hover {{ background: #1f2f55; }}
    .meta {{ color: #555; font-size: 0.95rem; line-height: 1.6; }}
    ul {{ padding-left: 1.2rem; }}
    li {{ margin: 6px 0; }}
    a {{ color: #0b57d0; }}
  </style>
</head>
<body>
  <h1>YFK Şartnameler — Toplu İndirme</h1>
  <p class="meta">Güncelleme: {html.escape(generated_at)}<br/>ZIP boyutu: {zip_bytes:,} bayt · {len(manifest_pdfs)} PDF</p>
  <a class="btn" href="{html.escape(ZIP_NAME)}" download>⬇️ Tümünü indir ({html.escape(ZIP_NAME)})</a>
  <h2>ZIP içindeki dosyalar</h2>
  <ul>
{"".join(f'    <li><a href="{html.escape(item["name"])}" download>{html.escape(str(item["name"]))}</a> ({int(item["bytes"]):,} bayt)</li>\\n' for item in manifest_pdfs)}
  </ul>
  <p class="meta">Kaynak: <a href="https://yfk.csb.gov.tr/sartnameler-i-330">yfk.csb.gov.tr/sartnameler-i-330</a></p>
</body>
</html>
"""

    (DOWNLOADS_DIR / "index.html").write_text(index_html, encoding="utf-8")
    (DOWNLOADS_DIR / "manifest.json").write_text(
        json.dumps(
            {
                "generated_at": generated_at,
                "zip": ZIP_NAME,
                "zip_bytes": zip_bytes,
                "pdf_count": len(manifest_pdfs),
                "files": manifest_pdfs,
            },
            ensure_ascii=False,
            indent=2,
        ),
        encoding="utf-8",
    )
    return target_zip


def pick_port(preferred: int) -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as sock:
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        try:
            sock.bind(("0.0.0.0", preferred))
            return preferred
        except OSError:
            sock.bind(("0.0.0.0", 0))
            return sock.getsockname()[1]


def serve(port: int) -> None:
    publish_artifacts()
    chosen = pick_port(port)
    handler = http.server.SimpleHTTPRequestHandler
    server = http.server.ThreadingHTTPServer(("0.0.0.0", chosen), handler)
    root = DOWNLOADS_DIR.resolve()
    print(f"İndirme sunucusu: http://127.0.0.1:{chosen}/")
    print(f"Doğrudan ZIP    : http://127.0.0.1:{chosen}/{ZIP_NAME}")
    print(f"Dizin           : {root}")
    print("Durdurmak için Ctrl+C")
    import os

    os.chdir(root)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nSunucu durduruldu.")


def main() -> int:
    parser = argparse.ArgumentParser(description="YFK şartname indirme sunucusu")
    parser.add_argument("--publish-only", action="store_true", help="ZIP/index dosyalarını güncelle, sunucu başlatma")
    parser.add_argument("--port", type=int, default=DEFAULT_PORT, help="Sunucu portu")
    args = parser.parse_args()

    zip_path = publish_artifacts()
    print(f"Yayınlandı: {zip_path}")

    if args.publish_only:
        print(f"Index: {DOWNLOADS_DIR / 'index.html'}")
        return 0

    serve(args.port)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
