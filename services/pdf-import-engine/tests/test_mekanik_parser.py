"""Tests for mekanik BFA parser."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from parsers.mekanik_bfa import parse_block  # noqa: E402

SAMPLE_BLOCK = [
    "Poz No",
    "25.100.1001",
    "Poz No",
    "Analizin Adı",
    "25X40 Cm Yaylı, Kancalı Veya Vidalı  Lavabolar   (Ts 605)",
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
    "20.100.1001 25X40 Cm Yaylı, Kancalı Veya Vidalı  Lavabolar",
    "(Ts 605)",
    "Ad",
    "1",
    "617,00",
    "617,00",
    "Montaj Bileşenleri",
    "10.100.1062 Düz işçi",
    "Sa",
    "0,2",
    "205,00",
    "41,00",
    "10.100.1084 Tesisat usta yardımcısı",
    "Sa",
    "0,5",
    "230,00",
    "115,00",
    "10.100.1082 Tesisat ustası",
    "Sa",
    "0,5",
    "310,00",
    "155,00",
    "% 25 Yüklenici Kârı ve",
    "Genel Giderler Dahil",
    "Kârsız Toplam (TL)",
    "Kârsız Malzeme ve Montaj (TL)",
    "Montaj Bedeli (TL)",
    "Birim Fiyat (TL)",
    "617,00",
    "928,00",
    "388,75",
    "1.160,00",
    "311,00",
]


def test_parse_block_basic():
    rec = parse_block(SAMPLE_BLOCK)
    assert rec["pozNo"] == "25.100.1001"
    assert "Lavabolar" in rec["analizAdi"]
    assert rec["olcuBirimi"] == "Ad"
    assert len(rec["kalemler"]) == 4
    assert rec["malzemeIscilikToplami"] == 928.0
    assert rec["birimFiyati"] == 1160.0
    assert rec["yukleniciKarTutari"] == 232.0


def test_kalem_types():
    rec = parse_block(SAMPLE_BLOCK)
    tips = [k["tip"] for k in rec["kalemler"]]
    assert tips[0] == "malzeme"
    assert all(t == "iscilik" for t in tips[1:])
