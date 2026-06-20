"""ÇŞB YFK Mekanik Tesisat B.F.A. PDF parser (2026 format)."""

from __future__ import annotations

import re
from typing import Any

POZ_BLOCK_CODE = re.compile(r"^25\.\d{3}\.\d{4}$")
KALEM_CODE = re.compile(r"^(\d{2}\.\d{3}\.\d{4})(?:\s+(.*))?$")
NUM = re.compile(r"^-?\d{1,3}(?:\.\d{3})*(?:,\d+)?$|^-?\d+(?:,\d+)?$")
FRAC = re.compile(r"^-?\d{1,3}(?:\.\d{3})*(?:,\d+)?\s*/\s*\d{1,3}(?:\.\d{3})*(?:,\d+)?$")
SCI = re.compile(r"^-?\d+(?:,\d+)?[eE]-?\d+$")
UNITS = {
    "Sa",
    "m³",
    "m2",
    "m3",
    "Kg",
    "kg",
    "m²",
    "m",
    "Ad",
    "Adet",
    "Kt",
    "lt",
    "Lt",
    "Ton",
    "ton",
    "Kwh",
    "kWh",
    "gr",
    "dm³",
    "%",
    "cm",
    "mm",
    "Tk",
    "takım",
    "Saat",
    "sa",
    "dm3",
    "kW",
    "kVA",
    "kcal",
    "Pa",
    "bar",
}


def _n(x: str) -> float:
    return float(x.strip().replace(".", "").replace(",", "."))


def to_float(s: str) -> float | None:
    s = s.strip()
    if NUM.match(s):
        return _n(s)
    if SCI.match(s):
        return float(s.replace(",", "."))
    if FRAC.match(s):
        a, b = s.split("/")
        try:
            return round(_n(a) / _n(b), 8)
        except ZeroDivisionError:
            return None
    return None


def is_amount(s: str) -> bool:
    s = s.strip()
    return bool(NUM.match(s) or FRAC.match(s) or SCI.match(s))


def extract_blocks(lines: list[str]) -> list[list[str]]:
    starts: list[int] = []
    for i, line in enumerate(lines):
        if POZ_BLOCK_CODE.match(line.strip()):
            j = i - 1
            while j >= 0 and not lines[j].strip():
                j -= 1
            if j >= 0 and lines[j].strip() == "Poz No":
                starts.append(j)
    return [
        lines[starts[k] : (starts[k + 1] if k + 1 < len(starts) else len(lines))]
        for k in range(len(starts))
    ]


def kalem_tip(section: str, poz_no: str) -> str:
    if poz_no.startswith("10."):
        return "iscilik"
    if poz_no.startswith("19."):
        return "ekipman"
    if section == "montaj":
        return "iscilik"
    return "malzeme"


def extract_category(analiz_adi: str) -> str:
    if " / " in analiz_adi:
        parts = [p.strip() for p in analiz_adi.split(" / ") if p.strip()]
        if parts:
            return parts[-1]
    return "Mekanik Tesisat"


def parse_block(blk: list[str]) -> dict[str, Any]:
    n = len(blk)

    def find(label: str, start: int = 0, exact: bool = True) -> int:
        for i in range(start, n):
            s = blk[i].strip()
            if (s == label) if exact else s.startswith(label):
                return i
        return -1

    poz_no = blk[1].strip() if n > 1 else None

    i_ad = find("Analizin Adı")
    i_tanim = find("Tanımı", i_ad if i_ad >= 0 else 0)
    analiz_adi = ""
    if i_ad >= 0 and i_tanim > i_ad:
        analiz_adi = " ".join(
            blk[k].strip() for k in range(i_ad + 1, i_tanim) if blk[k].strip()
        ).strip()

    i_ob = find("Ölçü Birimi", i_tanim if i_tanim >= 0 else 0)
    olcu_birimi = ""
    if i_ob >= 0:
        for k in range(i_ob + 1, min(n, i_ob + 4)):
            s = blk[k].strip()
            if s and s not in ("Montaj Tutarı", "(TL)", "Malzeme Bileşenleri"):
                olcu_birimi = s
                break

    i_totals = find("Birim Fiyat (TL)")
    kar_orani = 25
    mal_isc = kar_tutar = birim = None
    totals_start = i_totals

    i_kar = find("Yüklenici", i_tanim if i_tanim >= 0 else 0, exact=False)
    if i_kar >= 0:
        for k in range(i_kar, min(n, i_kar + 3)):
            mm = re.search(r"(\d+)\s*%\s*Yüklenici", blk[k].strip())
            if mm:
                kar_orani = int(mm.group(1))
                break

    if i_totals >= 0:
        nums: list[float] = []
        for k in range(i_totals + 1, min(n, i_totals + 8)):
            s = blk[k].strip()
            if re.match(r"^-\d+-$", s):
                break
            v = to_float(s)
            if v is not None:
                nums.append(v)
            elif s == "Poz No":
                break
        if len(nums) >= 4:
            # [kârsız malzeme, kârsız toplam, montaj+kâr, birim fiyat, montaj bedeli]
            mal_isc = nums[1]
            birim = nums[3]
            kar_tutar = round(birim - mal_isc, 2) if birim is not None and mal_isc is not None else None

    end_k = totals_start if totals_start >= 0 else n
    kalemler: list[dict[str, Any]] = []
    section = "malzeme"
    i = find("Malzeme Bileşenleri")
    if i < 0:
        i = i_tanim + 1 if i_tanim >= 0 else 0
    else:
        i += 1

    while i < end_k:
        s = blk[i].strip()
        low = s.lower()
        if low.startswith("montaj bileşenleri"):
            section = "montaj"
            i += 1
            continue
        if low.startswith("malzeme bileşenleri"):
            section = "malzeme"
            i += 1
            continue
        if KALEM_CODE.match(s):
            km = KALEM_CODE.match(s)
            kalem_poz = km.group(1) if km else s
            inline_tanim = (km.group(2) or "").strip() if km else ""
            parts: list[str] = [inline_tanim] if inline_tanim else []
            j = i + 1
            while j < end_k:
                t = blk[j].strip()
                if not t:
                    j += 1
                    continue
                if KALEM_CODE.match(t) or t.startswith("Montaj Bileşenleri") or t.startswith("Malzeme Bileşenleri"):
                    break
                if t.startswith("%") and "Yüklenici" in t:
                    break
                parts.append(t)
                if (
                    len(parts) >= 3
                    and NUM.match(parts[-1])
                    and NUM.match(parts[-2])
                    and is_amount(parts[-3])
                ):
                    j += 1
                    break
                j += 1
            if (
                len(parts) >= 3
                and NUM.match(parts[-1])
                and NUM.match(parts[-2])
                and is_amount(parts[-3])
            ):
                miktar = to_float(parts[-3])
                bf = to_float(parts[-2])
                tut = to_float(parts[-1])
                rest = parts[:-3]
                unit = ""
                if rest and rest[-1] in UNITS:
                    unit = rest[-1]
                    rest = rest[:-1]
                tanim = " ".join(rest).strip()
                kalemler.append(
                    {
                        "tip": kalem_tip(section, kalem_poz),
                        "pozNo": kalem_poz,
                        "tanim": tanim,
                        "olcuBirimi": unit,
                        "miktar": miktar,
                        "birimFiyati": bf,
                        "tutar": tut,
                    }
                )
                i = j
                continue
        i += 1

    if mal_isc is None and kalemler:
        mal_isc = round(sum(k["tutar"] or 0 for k in kalemler), 2)
    if birim is None and mal_isc is not None:
        kar_tutar = round(mal_isc * kar_orani / 100, 2)
        birim = round(mal_isc + kar_tutar, 2)

    return {
        "pozNo": poz_no,
        "analizAdi": analiz_adi,
        "olcuBirimi": olcu_birimi,
        "kategori": extract_category(analiz_adi),
        "kalemler": kalemler,
        "pozTarifi": "",
        "yapimSartlari": "",
        "olcusu": "",
        "yukleniciKarOrani": kar_orani,
        "malzemeIscilikToplami": mal_isc,
        "yukleniciKarTutari": kar_tutar,
        "birimFiyati": birim,
    }


def parse_mekanik_lines(lines: list[str]) -> dict[str, dict[str, Any]]:
    records: dict[str, dict[str, Any]] = {}
    for blk in extract_blocks(lines):
        rec = parse_block(blk)
        poz = rec.get("pozNo")
        if poz and POZ_BLOCK_CODE.match(poz):
            records[poz] = rec
    return records
