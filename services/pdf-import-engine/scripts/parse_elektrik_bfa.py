#!/usr/bin/env python3
"""Elektrik Tesisat B.F.A. PDF → Şantijet JSON dönüştürücü."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from parsers.elektrik_bfa import POZ_BLOCK_CODE, parse_elektrik_lines  # noqa: E402

UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
OUTPUT = Path(
    "/workspace/artifacts/imalat-poz-analizleri/assets/data/resmi-elektrik-analizleri.json"
)

CILT1_GLOBS = [
    "Elektrik_Tesisat_BFA_2026_Cilt1_Part*_of_10*.pdf",
    "ELEKTRIK_TESISAT_BFA_2026_CILT1_PART*_OF_10*.pdf",
    "*Elektrik*Tesisat*BFA*2026*Cilt1*Part*of*10*.pdf",
]
CILT2_GLOBS = [
    "Elektrik_Tesisat_BFA_2026_Cilt2_Part*_of_8*.pdf",
    "ELEKTRIK_TESISAT_BFA_2026_CILT2_PART*_OF_8*.pdf",
    "*Elektrik*Tesisat*BFA*2026*Cilt2*Part*of*8*.pdf",
]
CILT3_GLOBS = [
    "Elektrik_Tesisat_BFA_2026_Cilt3_Part*_of_6*.pdf",
    "ELEKTRIK_TESISAT_BFA_2026_CILT3_PART*_OF_6*.pdf",
    "*Elektrik*Tesisat*BFA*2026*Cilt3*Part*of*6*.pdf",
]

BATCH_GLOBS: dict[str, list[str]] = {
    "cilt1": CILT1_GLOBS,
    "cilt2": CILT2_GLOBS,
    "cilt3": CILT3_GLOBS,
    "cilt23": CILT2_GLOBS + CILT3_GLOBS,
    "all": CILT1_GLOBS + CILT2_GLOBS + CILT3_GLOBS,
}


def ws(s: str | None) -> str:
    if not s:
        return ""
    return re.sub(r"\s+", " ", s).strip()


def id_from_poz(poz: str) -> str:
    return "sys-elek-" + poz.replace(".", "x")


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
        "kategori": ws(rec.get("kategori")) or "Elektrik Tesisat",
        "kaynakTip": "sistem",
        "discipline": "elektrik",
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


def discover_pdfs(globs: list[str], search_dirs: list[Path]) -> list[Path]:
    found: dict[str, Path] = {}
    for directory in search_dirs:
        if not directory.exists():
            continue
        for pattern in globs:
            for path in sorted(directory.glob(pattern)):
                if path.is_file() and path.suffix.lower() == ".pdf":
                    found[str(path.resolve())] = path
    return sorted(found.values(), key=lambda p: _part_sort_key(p.name))


def _part_sort_key(name: str) -> tuple[int, int, str]:
    cilt = re.search(r"Cilt(\d+)", name, re.I)
    part = re.search(r"Part(\d+)_of_(\d+)", name, re.I)
    return (
        int(cilt.group(1)) if cilt else 999,
        int(part.group(1)) if part else 999,
        name.lower(),
    )


def dedupe_pdfs(paths: list[Path]) -> list[Path]:
    by_stem: dict[str, Path] = {}
    for path in paths:
        stem = re.sub(r"_[a-f0-9]{4}$", "", path.stem, flags=re.I)
        if stem not in by_stem or len(path.name) < len(by_stem[stem].name):
            by_stem[stem] = path
    return sorted(by_stem.values(), key=lambda p: _part_sort_key(p.name))


def resolve_pdf_list(batch: str, extra: list[str], search_dirs: list[Path]) -> list[Path]:
    if extra:
        paths = [Path(p).expanduser().resolve() for p in extra]
        missing = [p for p in paths if not p.exists()]
        if missing:
            print("Bulunamayan dosyalar:", [str(p) for p in missing])
            sys.exit(1)
        return sorted(paths, key=lambda p: _part_sort_key(p.name))

    globs = BATCH_GLOBS.get(batch, BATCH_GLOBS["all"])
    paths = dedupe_pdfs(discover_pdfs(globs, search_dirs))
    return paths


def load_existing_catalog() -> dict[str, dict]:
    if not OUTPUT.exists():
        return {}
    data = json.loads(OUTPUT.read_text(encoding="utf-8"))
    return {r["pozNo"]: r for r in data if isinstance(r, dict) and r.get("pozNo")}


def parse_pdfs(pdfs: list[Path]) -> dict[str, tuple[dict, str]]:
    merged: dict[str, tuple[dict, str]] = {}
    for pdf in pdfs:
        lines = get_lines(pdf)
        parsed = parse_elektrik_lines(lines)
        print(f"{pdf.name}: {len(parsed)} analiz ({pdf.stat().st_size // 1024} KB)")
        for poz, rec in parsed.items():
            if poz in merged:
                print(f"  UYARI: çift poz {poz} — {merged[poz][1]} vs {pdf.name}")
            merged[poz] = (rec, pdf.name)
    return merged


def write_catalog(
    parsed: dict[str, tuple[dict, str]],
    merge_existing: bool,
) -> tuple[list[dict], int, int]:
    existing = load_existing_catalog() if merge_existing else {}
    prev_count = len(existing)

    for poz, (rec, src) in parsed.items():
        existing[poz] = to_app_record(rec, src)

    out = list(existing.values())
    for r in out:
        r.pop("_meta", None)
    out.sort(key=lambda r: r["pozNo"])

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")

    added = len(out) - prev_count if merge_existing else len(out)
    return out, added, prev_count


def main() -> None:
    parser = argparse.ArgumentParser(description="Elektrik BFA PDF → JSON")
    parser.add_argument("pdfs", nargs="*", help="PDF dosya yolları")
    parser.add_argument(
        "--batch",
        choices=["cilt1", "cilt2", "cilt3", "cilt23", "all"],
        default="all",
        help="Otomatik keşif batch'i (varsayılan: all)",
    )
    parser.add_argument(
        "--merge",
        action="store_true",
        help="Mevcut JSON kataloğuna ekle/güncelle",
    )
    parser.add_argument(
        "--uploads-dir",
        type=Path,
        default=UPLOADS,
        help="PDF arama klasörü",
    )
    args = parser.parse_args()

    search_dirs = [args.uploads_dir, Path("/workspace/uploads"), Path.cwd()]
    pdfs = resolve_pdf_list(args.batch, args.pdfs, search_dirs)
    merge = args.merge or args.batch in ("cilt2", "cilt3", "cilt23")

    if not pdfs:
        print("PDF dosyası bulunamadı.")
        print(f"  batch={args.batch}")
        print(f"  aranan klasörler: {[str(d) for d in search_dirs if d.exists()]}")
        sys.exit(1)

    print(f"İşlenecek {len(pdfs)} PDF:")
    for p in pdfs:
        print(f"  - {p}")

    parsed = parse_pdfs(pdfs)
    out, added, prev = write_catalog(parsed, merge_existing=merge)

    no_name = [r["pozNo"] for r in out if not r["analizAdi"] or r["analizAdi"] == r["pozNo"]]
    no_kalem = [r["pozNo"] for r in out if not r["kalemler"]]
    no_price = [r["pozNo"] for r in out if not r["birimFiyati"]]

    print(f"\n=== Rapor ===")
    print(f"PDF'den parse edilen benzersiz poz: {len(parsed)}")
    if merge:
        print(f"Önceki katalog: {prev}")
        print(f"Yeni eklenen/güncellenen: {added}")
    print(f"Toplam katalog kaydı: {len(out)}")
    print(f"Adsız: {len(no_name)}")
    print(f"Kalemsiz: {len(no_kalem)}")
    print(f"Fiyatsız: {len(no_price)}")
    if no_name[:5]:
        print(f"  örnek adsız: {no_name[:5]}")
    print(f"Çıktı: {OUTPUT}")


if __name__ == "__main__":
    main()
