#!/usr/bin/env python3
"""Mekanik Tesisat B.F.A. PDF → Şantijet JSON dönüştürücü."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from parsers.mekanik_bfa import POZ_BLOCK_CODE, parse_mekanik_lines  # noqa: E402

DEFAULT_PDFS = [
    Path("/home/ubuntu/.cursor/projects/workspace/uploads/MEKAN_K_TES_SAT_B.F.A._2026_-1_da31.pdf"),
    Path("/home/ubuntu/.cursor/projects/workspace/uploads/MEKAN_K_TES_SAT_B.F.A._2026_-2_c0dc.pdf"),
]
OUTPUT = Path(
    "/workspace/artifacts/imalat-poz-analizleri/assets/data/resmi-mekanik-analizleri.json"
)


def ws(s: str | None) -> str:
    if not s:
        return ""
    return re.sub(r"\s+", " ", s).strip()


def id_from_poz(poz: str) -> str:
    return "sys-mek-" + poz.replace(".", "x")


def build_kalemler(pk: list[dict]) -> list[dict]:
    return [
        {
            "id": f"k{i}",
            "tip": k["tip"],
            "pozNo": k["pozNo"],
            "tanim": ws(k["tanim"]),
            "olcuBirimi": k["olcuBirimi"],
            "miktar": k["miktar"],
            "birimFiyati": k["birimFiyati"],
            "tutar": k["tutar"],
        }
        for i, k in enumerate(pk, 1)
    ]


def to_app_record(rec: dict, source_file: str) -> dict:
    now = "2026-01-01T00:00:00.000Z"
    poz = rec["pozNo"]
    analiz_adi = ws(rec["analizAdi"])
    if not analiz_adi or analiz_adi == poz:
        for k in rec.get("kalemler") or []:
            if k.get("tip") == "malzeme" and ws(k.get("tanim")):
                analiz_adi = ws(k["tanim"])
                break
    return {
        "id": id_from_poz(poz),
        "pozNo": poz,
        "analizAdi": analiz_adi or poz,
        "olcuBirimi": rec["olcuBirimi"] or "Ad",
        "kategori": ws(rec.get("kategori")) or "Mekanik Tesisat",
        "kaynakTip": "sistem",
        "discipline": "mekanik",
        "yukleniciKarOrani": rec["yukleniciKarOrani"],
        "malzemeIscilikToplami": round(rec["malzemeIscilikToplami"] or 0, 2),
        "yukleniciKarTutari": round(rec["yukleniciKarTutari"] or 0, 2),
        "birimFiyati": round(rec["birimFiyati"] or 0, 2),
        "olusturmaTarihi": now,
        "guncellemeTarihi": now,
        "pozTarifi": ws(rec.get("pozTarifi")),
        "yapimSartlari": ws(rec.get("yapimSartlari")),
        "olcusu": ws(rec.get("olcusu")),
        "kalemler": build_kalemler(rec.get("kalemler") or []),
        "_meta": {
            "kurum": "Çevre, Şehircilik ve İklim Değişikliği Bakanlığı",
            "yil": 2026,
            "kaynak_dosya": source_file,
        },
    }


def get_lines(pdf_path: Path) -> list[str]:
    doc = fitz.open(str(pdf_path))
    parts = [doc[i].get_text() for i in range(doc.page_count)]
    doc.close()
    return [line.rstrip() for line in "\n".join(parts).split("\n")]


def main() -> None:
    pdfs = [p for p in DEFAULT_PDFS if p.exists()]
    if not pdfs:
        print("PDF dosyaları bulunamadı:", DEFAULT_PDFS)
        sys.exit(1)

    merged: dict[str, tuple[dict, str]] = {}
    for pdf in pdfs:
        lines = get_lines(pdf)
        parsed = parse_mekanik_lines(lines)
        print(f"{pdf.name}: {len(parsed)} analiz")
        for poz, rec in parsed.items():
            if poz in merged:
                print(f"  UYARI: çift poz {poz} — {merged[poz][1]} vs {pdf.name}")
            merged[poz] = (rec, pdf.name)

    out = [to_app_record(rec, src) for rec, src in merged.values()]
    out.sort(key=lambda r: r["pozNo"])

    # _meta alanı uygulama JSON'unda tutulmaz; yalnızca doğrulama raporu için kullanılır
    for r in out:
        r.pop("_meta", None)

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    no_name = [r["pozNo"] for r in out if not r["analizAdi"] or r["analizAdi"] == r["pozNo"]]
    no_kalem = [r["pozNo"] for r in out if not r["kalemler"]]
    no_price = [r["pozNo"] for r in out if not r["birimFiyati"]]

    print(f"\nToplam kayıt: {len(out)}")
    print(f"Adsız: {len(no_name)}")
    print(f"Kalemsiz: {len(no_kalem)}")
    print(f"Fiyatsız: {len(no_price)}")
    if no_price[:5]:
        print("  örnek fiyatsız:", no_price[:5])
    print(f"Çıktı: {OUTPUT}")


if __name__ == "__main__":
    main()
