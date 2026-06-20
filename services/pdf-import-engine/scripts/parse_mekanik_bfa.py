#!/usr/bin/env python3
"""Mekanik Tesisat B.F.A. PDF → Şantijet JSON dönüştürücü."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

import fitz

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from parsers.mekanik_bfa import POZ_BLOCK_CODE, parse_mekanik_lines  # noqa: E402

UPLOADS = Path("/home/ubuntu/.cursor/projects/workspace/uploads")
OUTPUT = Path(
    "/workspace/artifacts/imalat-poz-analizleri/assets/data/resmi-mekanik-analizleri.json"
)

CILT12_GLOBS = [
    "MEKAN_K_TES_SAT_B.F.A._2026_-1_*.pdf",
    "MEKAN_K_TES_SAT_B.F.A._2026_-2_*.pdf",
    "MEKANIK_TESISAT_BFA_2026_-1*.pdf",
    "MEKANIK_TESISAT_BFA_2026_-2*.pdf",
]
CILT3_GLOBS = [
    "Mekanik_Tesisat_BFA_2026_Cilt3_Part*_of_5*.pdf",
    "MEKANIK_TESISAT_BFA_2026_CILT3_PART*_OF_5*.pdf",
    "*Cilt3*Part*of*5*.pdf",
]


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


def discover_pdfs(globs: list[str], search_dirs: list[Path]) -> list[Path]:
    found: dict[str, Path] = {}
    for directory in search_dirs:
        if not directory.exists():
            continue
        for pattern in globs:
            for path in sorted(directory.glob(pattern)):
                if path.is_file() and path.suffix.lower() == ".pdf":
                    found[str(path.resolve())] = path
    return sorted(found.values(), key=lambda p: p.name.lower())


def dedupe_pdfs(paths: list[Path]) -> list[Path]:
    """Aynı içerikli kopyaları (farklı hash soneki) eler — en kısa dosya adını tutar."""
    by_stem: dict[str, Path] = {}
    for path in paths:
        stem = re.sub(r"_[a-f0-9]{4}$", "", path.stem, flags=re.I)
        stem = re.sub(r"_[A-F0-9]{4}$", "", stem)
        if stem not in by_stem or len(path.name) < len(by_stem[stem].name):
            by_stem[stem] = path
    return sorted(by_stem.values(), key=lambda p: p.name.lower())


def resolve_pdf_list(batch: str, extra: list[str], search_dirs: list[Path]) -> list[Path]:
    if extra:
        paths = [Path(p).expanduser().resolve() for p in extra]
        missing = [p for p in paths if not p.exists()]
        if missing:
            print("Bulunamayan dosyalar:", [str(p) for p in missing])
            sys.exit(1)
        return paths

    globs: list[str] = []
    if batch in ("cilt12", "all"):
        globs.extend(CILT12_GLOBS)
    if batch in ("cilt3", "all"):
        globs.extend(CILT3_GLOBS)

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
        parsed = parse_mekanik_lines(lines)
        print(f"{pdf.name}: {len(parsed)} analiz ({pdf.stat().st_size // 1024} KB)")
        for poz, rec in parsed.items():
            if poz in merged:
                print(f"  UYARI: çift poz {poz} — {merged[poz][1]} vs {pdf.name}")
            merged[poz] = (rec, pdf.name)
    return merged


def write_catalog(
    parsed: dict[str, tuple[dict, str]],
    merge_existing: bool,
) -> list[dict]:
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
    parser = argparse.ArgumentParser(description="Mekanik BFA PDF → JSON")
    parser.add_argument(
        "pdfs",
        nargs="*",
        help="PDF dosya yolları (boşsa uploads klasöründen otomatik bulur)",
    )
    parser.add_argument(
        "--batch",
        choices=["cilt12", "cilt3", "all"],
        default="all",
        help="Otomatik keşif batch'i (varsayılan: all)",
    )
    parser.add_argument(
        "--merge",
        action="store_true",
        help="Mevcut JSON kataloğuna ekle/güncelle (yalnızca yeni PDF'ler için)",
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

    if not pdfs:
        print("PDF dosyası bulunamadı.")
        print(f"  batch={args.batch}")
        print(f"  aranan klasörler: {[str(d) for d in search_dirs if d.exists()]}")
        print("  Cilt3 glob:", CILT3_GLOBS)
        sys.exit(1)

    print(f"İşlenecek {len(pdfs)} PDF:")
    for p in pdfs:
        print(f"  - {p}")

    parsed = parse_pdfs(pdfs)
    out, added, prev = write_catalog(parsed, merge_existing=args.merge or args.batch == "cilt3")

    no_name = [r["pozNo"] for r in out if not r["analizAdi"] or r["analizAdi"] == r["pozNo"]]
    no_kalem = [r["pozNo"] for r in out if not r["kalemler"]]
    no_price = [r["pozNo"] for r in out if not r["birimFiyati"]]

    print(f"\n=== Rapor ===")
    print(f"PDF'den parse edilen benzersiz poz: {len(parsed)}")
    if args.merge or args.batch == "cilt3":
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
