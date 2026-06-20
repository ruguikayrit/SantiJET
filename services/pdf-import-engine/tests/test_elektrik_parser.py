"""Tests for elektrik BFA parser."""

from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from parsers.elektrik_bfa import parse_block  # noqa: E402

SAMPLE_BLOCK = [
    "Poz No",
    "35.100.1101",
    "Poz No",
    "Analizin Adı",
    "En ölçüsü en az 400 mm olan galvanizli dikili tip sac pano / Derinlik en az 400 mm / Dikili Tip",
    "Galvaniz Sac Panolar (1. Pano)",
    "Tanımı",
    "Ölçü",
    "Birimi",
    "Miktarı",
    "Birim Fiyatı",
    "Malzeme",
    "Tutarı (TL)",
    "Ölçü Birimi",
    "Ad",
    "Montaj Tutarı",
    "(TL)",
    "Malzeme Bileşenleri",
    "30.100.1101 En ölçüsü en az 400 mm olan galvanizli dikili tip sac",
    "pano / Derinlik en az 400 mm / Dikili Tip Galvaniz",
    "Sac Panolar (1. Pano)",
    "Ad",
    "1",
    "20.969,00",
    "20.969,00",
    "Montaj Bileşenleri",
    "10.100.1062 Düz işçi",
    "Sa",
    "1,75",
    "205,00",
    "358,75",
    "10.100.1081 Elektrik ustası",
    "Sa",
    "3,5",
    "310,00",
    "1.085,00",
    "10.100.1083 Elektrik usta yardımcısı",
    "Sa",
    "3,5",
    "230,00",
    "805,00",
    "19.100.1112 Forklift",
    "Sa",
    "0,5",
    "885,98",
    "442,99",
    "% 25 Yüklenici Kârı ve",
    "Genel Giderler Dahil",
    "Kârsız Toplam (TL)",
    "Kârsız Malzeme ve Montaj (TL)",
    "Montaj Bedeli (TL)",
    "Birim Fiyat (TL)",
    "20.969,00",
    "23.660,74",
    "3.364,67",
    "29.575,92",
    "2.691,74",
]


def test_parse_block_basic():
    rec = parse_block(SAMPLE_BLOCK)
    assert rec["pozNo"] == "35.100.1101"
    assert "Galvaniz" in rec["analizAdi"]
    assert rec["olcuBirimi"] == "Ad"
    assert len(rec["kalemler"]) == 5
    assert rec["malzemeIscilikToplami"] == 23660.74
    assert rec["birimFiyati"] == 29575.92


def test_kalem_types_include_ekipman():
    rec = parse_block(SAMPLE_BLOCK)
    tips = {k["pozNo"]: k["tip"] for k in rec["kalemler"]}
    assert tips["30.100.1101"] == "malzeme"
    assert tips["10.100.1081"] == "iscilik"
    assert tips["19.100.1112"] == "ekipman"
